from datetime import datetime

import sqlalchemy as sa

from .. import db


class TweetMark(db.Base):
    __tablename__ = 'tweet_marks'
    __table_args__ = (
        sa.UniqueConstraint('user_id', 'endpoint'),
    )

    id = sa.Column(sa.Integer, primary_key=True)
    user_id = sa.Column(sa.Integer, sa.ForeignKey('users.id'), nullable=False)

    endpoint = sa.Column(sa.String(64), nullable=False, unique=True)
    tweet_id = sa.Column(sa.BigInteger)

    # Metadata
    created_at = sa.Column(sa.DateTime,
                           server_default=sa.text('current_timestamp'))
    updated_at = sa.Column(sa.DateTime, onupdate=datetime.now)

    __attrs__ = ['id', 'user_id', 'endpoint', 'tweet_id']
