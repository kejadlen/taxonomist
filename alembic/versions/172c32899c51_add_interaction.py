"""Add Interaction

Revision ID: 172c32899c51
Revises: 4f15899c0da6
Create Date: 2015-01-14 18:21:06.261342

"""

# revision identifiers, used by Alembic.
revision = '172c32899c51'
down_revision = '4f15899c0da6'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_table('interactions',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('user_id', sa.Integer(), nullable=True),
                    sa.Column('interactee_id',
                              sa.BigInteger(),
                              nullable=False),
                    sa.Column('count', sa.Integer(), default=0),
                    sa.Column('created_at',
                              sa.DateTime(),
                              server_default=sa.text(u'current_timestamp'),
                              nullable=True),
                    sa.Column('updated_at', sa.DateTime(), nullable=True),
                    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
                    sa.PrimaryKeyConstraint('id'))


def downgrade():
    op.drop_table('interactions')
