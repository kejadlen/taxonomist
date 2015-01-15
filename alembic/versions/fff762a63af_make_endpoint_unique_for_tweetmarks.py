"""Make endpoint unique for TweetMarks

Revision ID: fff762a63af
Revises: 172c32899c51
Create Date: 2015-01-14 20:59:54.158967

"""

# revision identifiers, used by Alembic.
revision = 'fff762a63af'
down_revision = '172c32899c51'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_unique_constraint(None, 'tweet_marks', ['endpoint'])


def downgrade():
    op.drop_constraint(None, 'tweet_marks', type_='unique')
