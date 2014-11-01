import os
from datetime import datetime, timedelta

import networkx as nx
from sqlalchemy import text, BigInteger, Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY, JSON
from sqlalchemy.ext.mutable import MutableDict
from sqlalchemy.orm import relationship

import db
from cliques import SLPA
from list import List
from twitter import Twitter


class User(db.Base):
    STALE = timedelta(weeks=4)

    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)

    # Twitter data
    twitter_id = Column(BigInteger, nullable=False, unique=True)
    friend_ids = Column(ARRAY(BigInteger))
    raw = Column(JSON(none_as_null=True))
    oauth_token = Column(String(255))
    oauth_token_secret = Column(String(255))

    # Metadata
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)

    # Relationships
    lists = relationship('List', backref='user')

    def __init__(self, twitter_id, raw=None):
        self.twitter_id = twitter_id
        # self.screen_name = screen_name
        self.raw = raw

    def __repr__(self):
        return '<User %r, %r>' % (self.twitter_id, self.screen_name)

    @property
    def dehydrated_friends(self):
        return self.friends.filter(User.raw.is_(None))

    @property
    def friend_graph(self):
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
    def screen_name(self):
        return self.raw['screen_name']

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
