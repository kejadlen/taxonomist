from datetime import datetime, timedelta

from sqlalchemy import text, BigInteger, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import backref, relationship

import db


class List(db.Base):
    STALE = timedelta(weeks=4)

    __tablename__ = 'lists'

    id = Column(Integer, primary_key=True)
    twitter_id = Column(BigInteger, nullable=False, unique=True)
    name = Column(String(32))
    member_ids = Column(ARRAY(BigInteger))
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)

    user_id = Column(BigInteger, ForeignKey('users.id'), nullable=False)
    # user = relationship('User', backref=backref('lists', order_by=id))

    def __init__(self, raw):
        self.twitter_id = raw['id']
        self.name = raw['name']

    def __repr__(self):
        return '<List %r, %r>' % (self.twitter_id, self.name)

    @property
    def is_stale(self):
        return (self.updated_at is None or
                datetime.now() - self.updated_at > self.STALE)
