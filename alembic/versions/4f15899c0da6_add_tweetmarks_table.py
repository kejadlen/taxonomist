"""Add TweetMarks table

Revision ID: 4f15899c0da6
Revises: 35625c5bc144
Create Date: 2015-01-14 17:23:21.289958

"""

# revision identifiers, used by Alembic.
revision = '4f15899c0da6'
down_revision = '35625c5bc144'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_table('tweet_marks',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('endpoint',
                              sa.String(length=64),
                              nullable=False),
                    sa.Column('since_id', sa.BigInteger(), nullable=True),
                    sa.Column('max_id', sa.BigInteger(), nullable=True),
                    sa.Column('user_id', sa.Integer(), nullable=False),
                    sa.Column('created_at',
                              sa.DateTime(),
                              server_default=sa.text(u'current_timestamp'),
                              nullable=True),
                    sa.Column('updated_at', sa.DateTime(), nullable=True),
                    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
                    sa.PrimaryKeyConstraint('id'))
    op.create_index(op.f('ix_users_twitter_id'),
                    'users',
                    ['twitter_id'],
                    unique=True)
    op.drop_constraint(u'users_twitter_id_key', 'users', type_='unique')


def downgrade():
    op.create_unique_constraint(u'users_twitter_id_key',
                                'users',
                                ['twitter_id'])
    op.drop_index(op.f('ix_users_twitter_id'), table_name='users')
    op.drop_table('tweet_marks')
