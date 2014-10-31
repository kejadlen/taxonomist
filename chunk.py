from datetime import datetime

from sqlalchemy import text, BigInteger, Column, DateTime, ForeignKey, Integer, String

import db

class Chunk(db.Base):
    __tablename__ = 'chunks'

    id = Column(Integer, primary_key=True)
    endpoint = Column(String(32))
    oldest_id = Column(BigInteger)
    newest_id = Column(BigInteger)
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)

    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
