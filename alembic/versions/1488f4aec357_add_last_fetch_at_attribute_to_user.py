"""Add last_fetch_at attribute to User

Revision ID: 1488f4aec357
Revises: 4c3c8a211ea3
Create Date: 2015-01-16 22:37:01.674055

"""

# revision identifiers, used by Alembic.
revision = '1488f4aec357'
down_revision = '4c3c8a211ea3'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('users',
                  sa.Column('last_fetch_at', sa.DateTime(), nullable=True))


def downgrade():
    op.drop_column('users', 'last_fetch_at')
