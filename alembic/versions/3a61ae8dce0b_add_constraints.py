"""Add constraints

Revision ID: 3a61ae8dce0b
Revises: 12a1f159d90
Create Date: 2015-01-16 15:12:51.929123

"""

# revision identifiers, used by Alembic.
revision = '3a61ae8dce0b'
down_revision = '12a1f159d90'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_unique_constraint(None,
                                'interactions',
                                ['user_id', 'type', 'interactee_id'])
    op.create_unique_constraint(None, 'tweet_marks', ['user_id', 'endpoint'])


def downgrade():
    op.drop_constraint(None, 'tweet_marks', type_='unique')
    op.drop_constraint(None, 'interactions', type_='unique')
