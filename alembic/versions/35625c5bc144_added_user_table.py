"""Added User table

Revision ID: 35625c5bc144
Revises:
Create Date: 2014-12-13 15:25:48.119598

"""

# revision identifiers, used by Alembic.
revision = '35625c5bc144'
down_revision = None
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


def upgrade():
    op.create_table('users',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('twitter_id', sa.BigInteger, nullable=False),
                    sa.Column('friend_ids',
                              postgresql.ARRAY(sa.BigInteger),
                              nullable=True),
                    sa.Column('raw',
                              postgresql.JSON(none_as_null=True),
                              nullable=True),
                    sa.Column('oauth_token',
                              sa.String(length=255),
                              nullable=True),
                    sa.Column('oauth_token_secret',
                              sa.String(length=255),
                              nullable=True),
                    sa.Column('created_at',
                              sa.DateTime(),
                              server_default=sa.text(u'current_timestamp'),
                              nullable=True),
                    sa.Column('updated_at', sa.DateTime(), nullable=True),
                    sa.PrimaryKeyConstraint('id'),
                    sa.UniqueConstraint('twitter_id')
                    )


def downgrade():
    op.drop_table('users')
