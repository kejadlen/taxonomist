from datetime import datetime

from sqlalchemy import text, BigInteger, Column, \
    DateTime, ForeignKey, Integer, String

from .. import db


class TweetMark(db.Base):
    __tablename__ = 'tweet_marks'

    id = Column(Integer, primary_key=True)

    endpoint = Column(String(64), nullable=False)
    since_id = Column(BigInteger)
    max_id = Column(BigInteger)

    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)

    # Metadata
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)
