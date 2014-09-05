import datetime
import os

from sqlalchemy import BigInteger, Column, DateTime, Integer, String
from sqlalchemy import create_engine, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker

from twitter import Twitter

engine = create_engine(os.environ['DATABASE'], echo=True)
db_session = scoped_session(sessionmaker(autocommit=False,
                                         autoflush=False,
                                         bind=engine))

Base = declarative_base()
Base.query = db_session.query_property()

class User(Base):
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
        return Twitter(self.oauth_token, self.oauth_token_secret)

def init_db():
    Base.metadata.create_all(bind=engine)
