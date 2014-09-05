import datetime
import os

import db
from sqlalchemy import text, BigInteger, Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY

from twitter import Twitter

class User(db.Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    twitter_id = Column(BigInteger, nullable=False, unique=True)
    screen_name = Column(String(32))
    friend_ids = Column(ARRAY(BigInteger))
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.datetime.now)
    oauth_token = Column(String(255))
    oauth_token_secret = Column(String(255))

    def __init__(self, twitter_id):
        self.twitter_id = twitter_id

    def __repr__(self):
        return '<User %r>' % (self.twitter_id)

    @property
    def twitter(self):
        if self.oauth_token is None or self.oauth_token_secret is None:
            return None
        else:
            return Twitter(self.oauth_token, self.oauth_token_secret)
