from datetime import datetime
import os

from sqlalchemy.dialects.postgresql import ARRAY, JSON
from sqlalchemy.orm import relationship
import sqlalchemy as sa

from .. import db
from .. import twitter
import interaction
import tweet_mark


class User(db.Base):
    __tablename__ = 'users'

    id = sa.Column(sa.Integer, primary_key=True)

    # Relationships
    interactions = relationship('Interaction')
    tweet_marks = relationship('TweetMark')

    # Twitter data
    twitter_id = sa.Column(sa.BigInteger,
                           index=True, nullable=False, unique=True)
    friend_ids = sa.Column(ARRAY(sa.BigInteger))
    raw = sa.Column(JSON(none_as_null=True))
    oauth_token = sa.Column(sa.String(255))
    oauth_token_secret = sa.Column(sa.String(255))

    # Metadata
    last_fetch_at = sa.Column(sa.DateTime)
    created_at = sa.Column(sa.DateTime,
                           server_default=sa.text('current_timestamp'))
    updated_at = sa.Column(sa.DateTime, onupdate=datetime.now)

    __attrs__ = ['id', 'twitter_id']

    @property
    def friends(self):
        return User.query.filter(User.twitter_id.in_(self.friend_ids))

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
