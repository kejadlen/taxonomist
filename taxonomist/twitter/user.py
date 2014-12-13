from datetime import datetime

from sqlalchemy import text, BigInteger, Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY, JSON
# from sqlalchemy.ext.mutable import MutableDict
# from sqlalchemy.orm import relationship

from taxonomist.twitter import Base

class User(Base):
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

    def __init__(self, twitter_id, raw=None):
        self.twitter_id = twitter_id
        # self.screen_name = screen_name
        self.raw = raw
