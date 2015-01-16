"""Use more sensible attributes for TweetMarks

Revision ID: 25d88e34e19f
Revises: fff762a63af
Create Date: 2015-01-15 15:49:30.821813

"""

# revision identifiers, used by Alembic.
revision = '25d88e34e19f'
down_revision = 'fff762a63af'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('tweet_marks',
                  sa.Column('newest', sa.BigInteger(), nullable=True))
    op.add_column('tweet_marks',
                  sa.Column('oldest', sa.BigInteger(), nullable=True))
    op.drop_column('tweet_marks', 'max_id')
    op.drop_column('tweet_marks', 'since_id')


def downgrade():
    op.add_column('tweet_marks',
                  sa.Column('since_id',
                            sa.BIGINT(),
                            autoincrement=False,
                            nullable=True))
    op.add_column('tweet_marks',
                  sa.Column('max_id',
                            sa.BIGINT(),
                            autoincrement=False,
                            nullable=True))
    op.drop_column('tweet_marks', 'oldest')
    op.drop_column('tweet_marks', 'newest')
