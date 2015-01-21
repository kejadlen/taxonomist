from datetime import datetime
import os

import networkx as nx
from sqlalchemy.dialects.postgresql import ARRAY, HSTORE, JSON
from sqlalchemy.ext.mutable import MutableDict
from sqlalchemy.orm import relationship
import sqlalchemy as sa

from . import interaction
from . import tweet_mark
from .. import db
from .. import twitter


class User(db.Base):
    __tablename__ = 'users'

    id = sa.Column(sa.Integer, primary_key=True)

    # Relationships
    interactions = relationship('Interaction')
    lists = relationship('List')
    tweet_marks = relationship('TweetMark')

    # Twitter data
    twitter_id = sa.Column(sa.BigInteger,
                           index=True, nullable=False, unique=True)
    friend_ids = sa.Column(ARRAY(sa.BigInteger))
    raw = sa.Column(JSON(none_as_null=True))
    oauth_token = sa.Column(sa.String(255))
    oauth_token_secret = sa.Column(sa.String(255))

    # Metadata
    fetched_ats = sa.Column(MutableDict.as_mutable(HSTORE), default={})
    created_at = sa.Column(sa.DateTime,
                           server_default=sa.text('current_timestamp'))
    updated_at = sa.Column(sa.DateTime, onupdate=datetime.now)

    __attrs__ = ['id', 'twitter_id']

    @property
    def friends(self):
        # TODO Make friend_ids default to an empty list
        friend_ids = self.friend_ids or []
        return User.query.filter(User.twitter_id.in_(friend_ids))

    @property
    def screen_name(self):
        return self.raw['screen_name']

    @property
    def twitter(self):
        if not self.oauth_token or not self.oauth_token_secret:
            return None
        else:
            return twitter.AuthedClient(os.environ['TWITTER_API_KEY'],
                                        os.environ['TWITTER_API_SECRET'],
                                        self.oauth_token,
                                        self.oauth_token_secret)

    @property
    def graph(self):
        graph = nx.Graph()
        nodes = [friend for friend in self.friends
                 if friend.friend_ids and friend != self]
        for node in nodes:
            edges = [(node.twitter_id, friend_id)
                     for friend_id in node.friend_ids
                     if friend_id in self.friend_ids and
                     friend_id != self.twitter_id]
            if edges:
                graph.add_node(node.twitter_id, screen_name=node.screen_name)
                graph.add_edges_from(edges)
        return graph
