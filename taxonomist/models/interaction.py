from datetime import datetime

import sqlalchemy as sa

from .. import db
from ..twitter import retry_rate_limited


class Interaction(db.Base):
    __tablename__ = 'interactions'
    __table_args__ = (
        sa.UniqueConstraint('user_id', 'type', 'interactee_id'),
    )

    id = sa.Column(sa.Integer, primary_key=True)

    user_id = sa.Column(sa.Integer, sa.ForeignKey('users.id'))

    interactee_id = sa.Column(sa.BigInteger, nullable=False)
    count = sa.Column(sa.Integer, default=0)
    type = sa.Column(sa.String(32))

    # Metadata
    created_at = sa.Column(sa.DateTime,
                           server_default=sa.text('current_timestamp'))
    updated_at = sa.Column(sa.DateTime, onupdate=datetime.now)

    __mapper_args__ = {'polymorphic_on': type,
                       'polymorphic_identity': 'interaction'}

    __attrs__ = ['id', 'user_id', 'interactee_id', 'count']


class Mention(Interaction):
    __mapper_args__ = {'polymorphic_identity': 'mention'}

    @classmethod
    @retry_rate_limited
    def fetch(cls, twitter, user, since_id=None, max_id=None):
        return twitter.statuses_user_timeline(user.twitter_id,
                                              since_id=since_id,
                                              max_id=max_id)

    @classmethod
    def interactee_ids(cls, tweet):
        return [user['id'] for user in tweet['entities']['user_mentions']]

class Favorite(Interaction):
    __mapper_args__ = {'polymorphic_identity': 'favorite'}

    @classmethod
    @retry_rate_limited
    def fetch(cls, twitter, user, since_id=None, max_id=None):
        return twitter.favorites_list(user.twitter_id,
                                      since_id=since_id,
                                      max_id=max_id)

    @classmethod
    def interactee_ids(cls, tweet):
        return [tweet['user']['id']]

class DM(Interaction):
    __mapper_args__ = {'polymorphic_identity': 'dm'}

    @classmethod
    @retry_rate_limited
    def fetch(cls, twitter, user=None, since_id=None, max_id=None):
        return twitter.direct_messages_sent(since_id=since_id, max_id=max_id)

    @classmethod
    def interactee_ids(cls, dm):
        return [dm['recipient_id']]
