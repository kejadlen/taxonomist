from datetime import datetime
import os

import networkx as nx
from sqlalchemy.dialects.postgresql import ARRAY, HSTORE, JSON
from sqlalchemy.ext.mutable import MutableDict
from sqlalchemy.orm import relationship
import sqlalchemy as sa

from . import interaction
from .. import db
from .. import twitter
from ..slpa import SLPA
from .list import List
from .tweet_mark import TweetMark


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
    friend_ids = sa.Column(ARRAY(sa.BigInteger), nullable=False)
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
    def friend_graph(self):
        graph = nx.Graph()

        for friend in self.friends:
            graph.add_node(friend.twitter_id, screen_name=friend.screen_name)

            for stranger_id in friend.friend_ids:
                graph.add_edge(friend.twitter_id, stranger_id)

        graph.remove_node(self.twitter_id)

        for node in graph.nodes():
            if graph.degree(node) < 2:
                graph.remove_node(node)

        return graph

    @property
    def friends(self):
        if not self.friend_ids:
            return []

        return User.query.filter(User.twitter_id.in_(self.friend_ids))

    @property
    def last_tweet_at(self):
        status = self.raw['status']
        return status and datetime.strptime(status['created_at'],
                                            '%a %b %d %H:%M:%S %z %Y')

    @property
    def name(self):
        return self.raw['name']

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

    def cliques(self, r=0.5):
        slpa = SLPA(self.friend_graph)

        cliques = slpa.cliques(r=r)
        cliques = cliques.values()
        cliques = [[twitter_id for twitter_id in clique
                    if twitter_id in self.friend_ids]
                   for clique in cliques]

        return cliques
