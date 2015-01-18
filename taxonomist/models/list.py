from datetime import datetime

from sqlalchemy.dialects.postgresql import ARRAY, JSON
import sqlalchemy as sa

from .. import db


class List(db.Base):
    __tablename__ = 'lists'
    __table_args__ = (
        sa.UniqueConstraint('user_id', 'list_id'),
    )

    id = sa.Column(sa.Integer, primary_key=True)
    user_id = sa.Column(sa.Integer, sa.ForeignKey('users.id'), nullable=False)
    list_id = sa.Column(sa.BigInteger)
    member_ids = sa.Column(ARRAY(sa.BigInteger))
    raw = sa.Column(JSON(none_as_null=True))

    # Metadata
    fetched_at = sa.Column(sa.DateTime)
    created_at = sa.Column(sa.DateTime,
                           server_default=sa.text('current_timestamp'))
    updated_at = sa.Column(sa.DateTime, onupdate=datetime.now)

    __attrs__ = ['id', 'user_id', 'list_id']

# https://dev.twitter.com/rest/reference/get/lists/members

# https://dev.twitter.com/rest/reference/post/lists/members/create_all
# https://dev.twitter.com/rest/reference/post/lists/members/destroy_all

# https://dev.twitter.com/rest/reference/post/lists/create
