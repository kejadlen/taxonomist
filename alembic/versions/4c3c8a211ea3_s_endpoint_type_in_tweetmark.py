"""s/endpoint/type/ in TweetMark

Revision ID: 4c3c8a211ea3
Revises: 3a61ae8dce0b
Create Date: 2015-01-16 20:32:58.809800

"""

# revision identifiers, used by Alembic.
revision = '4c3c8a211ea3'
down_revision = '3a61ae8dce0b'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    # Yup, I'm deleting everything since they're invalid now!
    op.execute(sa.sql.table('interactions').delete())
    op.execute(sa.sql.table('tweet_marks').delete())

    op.add_column('tweet_marks', sa.Column('type',
                                           sa.String(length=64),
                                           nullable=False))
    op.drop_constraint(u'tweet_marks_endpoint_key',
                       'tweet_marks',
                       type_='unique')
    op.drop_constraint(u'tweet_marks_user_id_endpoint_key',
                       'tweet_marks',
                       type_='unique')
    op.create_unique_constraint(None, 'tweet_marks', ['user_id', 'type'])
    op.create_unique_constraint(None, 'tweet_marks', ['type'])
    op.drop_column('tweet_marks', 'endpoint')


def downgrade():
    op.add_column('tweet_marks', sa.Column('endpoint',
                                           sa.VARCHAR(length=64),
                                           autoincrement=False,
                                           nullable=False))
    op.drop_constraint(None, 'tweet_marks', type_='unique')
    op.drop_constraint(None, 'tweet_marks', type_='unique')
    op.create_unique_constraint(u'tweet_marks_user_id_endpoint_key',
                                'tweet_marks',
                                ['user_id', 'endpoint'])
    op.create_unique_constraint(u'tweet_marks_endpoint_key',
                                'tweet_marks',
                                ['endpoint'])
    op.drop_column('tweet_marks', 'type')
