from datetime import datetime
import os

from sqlalchemy import text, BigInteger, Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY, JSON
from sqlalchemy.orm import relationship

from .. import db
from .. import twitter
import interaction
import tweet_mark


class User(db.Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)

    # Relationships
    interactions = relationship('Interaction')
    tweet_marks = relationship('TweetMark')

    # Twitter data
    twitter_id = Column(BigInteger, index=True, nullable=False, unique=True)
    friend_ids = Column(ARRAY(BigInteger))
    raw = Column(JSON(none_as_null=True))
    oauth_token = Column(String(255))
    oauth_token_secret = Column(String(255))

    # Metadata
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)

    @property
    def friends(self):
        return User.query.filter(User.twitter_id.in_(self.friend_ids))

    @property
    def twitter(self):
        if not self.oauth_token or not self.oauth_token_secret:
            return None
        else:
            return twitter.AuthedClient(os.environ['TWITTER_API_KEY'],
                                        os.environ['TWITTER_API_SECRET'],
                                        self.oauth_token,
                                        self.oauth_token_secret)
