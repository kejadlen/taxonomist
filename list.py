from datetime import datetime, timedelta
from itertools import izip_longest

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

    def __init__(self, user, raw):
        self.user = user
        self.twitter_id = raw['id']
        self.name = raw['name']

    def __repr__(self):
        return '<List %r, %r>' % (self.twitter_id, self.name)

    @property
    def is_stale(self):
        return (self.updated_at is None or
                datetime.now() - self.updated_at > self.STALE)

    def add_users(self, users):
        missing_ids = [user.twitter_id for user in users
                       if user.twitter_id not in self.member_ids]

        if not missing_ids:
            return

        chunks = izip_longest(*([iter(user_ids)] * 100))
        for chunk in chunks:
            chunk = [id for id in chunk if id]
            self.user.twitter.lists_members_create_all(self.twitter_id, chunk)
