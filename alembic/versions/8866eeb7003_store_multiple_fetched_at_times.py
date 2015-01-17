"""Store multiple fetched_at times

Revision ID: 8866eeb7003
Revises: 1488f4aec357
Create Date: 2015-01-17 08:18:46.830884

"""

# revision identifiers, used by Alembic.
revision = '8866eeb7003'
down_revision = '1488f4aec357'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


def upgrade():
    op.execute('create extension if not exists hstore')

    op.add_column('users',
                  sa.Column('fetched_ats', postgresql.HSTORE(), nullable=True))
    op.drop_column('users', 'last_fetch_at')


def downgrade():
    op.add_column('users',
                  sa.Column('last_fetch_at',
                            postgresql.TIMESTAMP(),
                            autoincrement=False,
                            nullable=True))
    op.drop_column('users', 'fetched_ats')

    op.execute('drop extension if exists hstore')
