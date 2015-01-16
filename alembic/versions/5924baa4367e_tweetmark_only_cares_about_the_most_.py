"""TweetMark only cares about the most recent weet

Revision ID: 5924baa4367e
Revises: 25d88e34e19f
Create Date: 2015-01-15 15:54:47.085383

"""

# revision identifiers, used by Alembic.
revision = '5924baa4367e'
down_revision = '25d88e34e19f'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('tweet_marks',
                  sa.Column('tweet_id', sa.BigInteger(), nullable=True))
    op.drop_column('tweet_marks', 'oldest')
    op.drop_column('tweet_marks', 'newest')


def downgrade():
    op.add_column('tweet_marks',
                  sa.Column('newest',
                            sa.BIGINT(),
                            autoincrement=False,
                            nullable=True))
    op.add_column('tweet_marks',
                  sa.Column('oldest',
                            sa.BIGINT(),
                            autoincrement=False,
                            nullable=True))
    op.drop_column('tweet_marks', 'tweet_id')
