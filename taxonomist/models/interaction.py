from datetime import datetime

from sqlalchemy import text, BigInteger, Column, DateTime, ForeignKey, Integer

from .. import db


class Interaction(db.Base):
    __tablename__ = 'interactions'

    id = Column(Integer, primary_key=True)

    user_id = Column(Integer, ForeignKey('users.id'))

    interactee_id = Column(BigInteger, nullable=False)
    count = Column(Integer, default=0)

    # Metadata
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.now)
