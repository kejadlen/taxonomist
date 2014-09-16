from datetime import datetime

from sqlalchemy import text, BigInteger, Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY

import db


class List(db.Base):
    __tablename__ = 'lists'

    id = Column(Integer, primary_key=True)
    twitter_id = Column(BigInteger, nullable=False, unique=True)
    name = Column(String(32))
    member_ids = Column(ARRAY(BigInteger))
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)

    def __init__(self, raw):
        self.twitter_id = raw['id']
        self.name = raw['name']
