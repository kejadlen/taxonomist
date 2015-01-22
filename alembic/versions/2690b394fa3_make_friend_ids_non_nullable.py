"""Make friend_ids non-nullable

Revision ID: 2690b394fa3
Revises: 8866eeb7003
Create Date: 2015-01-21 16:32:00.996777

"""

# revision identifiers, used by Alembic.
revision = '2690b394fa3'
down_revision = '8866eeb7003'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


def upgrade():
    op.alter_column('users', 'friend_ids',
                    existing_type=postgresql.ARRAY(sa.BIGINT()),
                    nullable=False)


def downgrade():
    op.alter_column('users', 'friend_ids',
                    existing_type=postgresql.ARRAY(sa.BIGINT()),
                    nullable=True)
