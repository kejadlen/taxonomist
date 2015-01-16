from datetime import datetime

import sqlalchemy as sa

from .. import db


class Interaction(db.Base):
    __tablename__ = 'interactions'

    id = sa.Column(sa.Integer, primary_key=True)

    user_id = sa.Column(sa.Integer, sa.ForeignKey('users.id'))

    interactee_id = sa.Column(sa.BigInteger, nullable=False)
    count = sa.Column(sa.Integer, default=0)
    type = sa.Column(sa.String(32))

    # Metadata
    created_at = sa.Column(sa.DateTime,
                           server_default=sa.text('current_timestamp'))
    updated_at = sa.Column(sa.DateTime, onupdate=datetime.now)

    __mapper_args__ = {'polymorphic_on':type,
                       'polymorphic_identity':'interaction'}

    __attrs__ = ['id', 'user_id', 'interactee_id', 'count']


class Mention(Interaction):
    __mapper_args__ = {'polymorphic_identity':'mention'}

class Favorite(Interaction):
    __mapper_args__ = {'polymorphic_identity':'favorite'}

class DM(Interaction):
    __mapper_args__ = {'polymorphic_identity':'dm'}
