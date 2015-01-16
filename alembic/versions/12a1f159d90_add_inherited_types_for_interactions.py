"""Add inherited types for Interactions

Revision ID: 12a1f159d90
Revises: 5924baa4367e
Create Date: 2015-01-16 08:36:18.331051

"""

# revision identifiers, used by Alembic.
revision = '12a1f159d90'
down_revision = '5924baa4367e'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('interactions',
                  sa.Column('type', sa.String(length=32), nullable=True))


def downgrade():
    op.drop_column('interactions', 'type')
