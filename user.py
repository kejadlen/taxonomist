import os
from datetime import datetime, timedelta

import db
import networkx as nx
from sqlalchemy import text, BigInteger, Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY, HSTORE

from cliques import SLPA
from twitter import Twitter


class User(db.Base):
    __tablename__ = 'users'

    STALE = timedelta(weeks=4)

    id = Column(Integer, primary_key=True)
    twitter_id = Column(BigInteger, nullable=False, unique=True)
    screen_name = Column(String(32))
    friend_ids = Column(ARRAY(BigInteger))
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)
    oauth_token = Column(String(255))
    oauth_token_secret = Column(String(255))

    def __init__(self, twitter_id, screen_name=None):
        self.twitter_id = twitter_id
        self.screen_name = screen_name

    def __repr__(self):
        return '<User %r, %r>' % (self.twitter_id, self.screen_name)

    @property
    def dehydrated_friends(self):
        return self.friends.filter(User.screen_name.is_(None))

    @property
    def graph(self):
        graph = nx.Graph()
        for friend in [friend for friend in self.friends if friend.friend_ids]:
            graph.add_node(friend.twitter_id, screen_name=friend.screen_name)
            edges = [(friend.twitter_id, friend_id)
                        for friend_id in friend.friend_ids
                        if friend_id in self.friend_ids and
                        friend_id != self.twitter_id]
            graph.add_edges_from(edges)
        return graph

    @property
    def is_stale(self):
        return (self.updated_at is None or
                datetime.now() - self.updated_at > self.STALE)

    @property
    def friends(self):
        return User.query.filter(User.twitter_id.in_(self.friend_ids))

    @property
    def stale_friends(self):
        return [friend for friend in self.friends if friend.is_stale]

    @property
    def twitter(self):
        if not self.oauth_token or not self.oauth_token_secret:
            return None
        else:
            return Twitter(self.oauth_token, self.oauth_token_secret)

    def cliques(self, **kwargs):
        cliques = SLPA(self.graph).cliques(**kwargs)

        friends = self.friends
        friends = {friend.twitter_id:friend for friend in friends}
        return {friends[label]:[friends[id] for id in clique]
                for label, clique in cliques.iteritems()
                if len(clique) > 1}

    def create_friends(self):
        existing_ids = [friend.twitter_id for friend in self.friends]
        missing_ids = [id for id in self.friend_ids if id not in existing_ids]
        for id in missing_ids:
            db.session.add(User(id))
        db.session.commit()
