from datetime import datetime, timedelta
import logging

from .. import db
from ..models.user import User


class Task:
    STALE = timedelta(weeks=1)

    # TODO Add jitter
    @classmethod
    def is_stale(cls, user):
        key = cls.__name__

        if key not in user.fetched_ats:
            return True

        fetched_at = datetime.strptime(user.fetched_ats[key],
                                       '%Y-%m-%dT%H:%M:%S.%f')
        return datetime.now() - fetched_at > cls.STALE

    def __init__(self, twitter):
        self.twitter = twitter
        self.logger = logging.getLogger('taxonomist')

    def create_users(self, twitter_ids):
        users = User.query.filter(User.twitter_id.in_(twitter_ids))
        existing_ids = [user.twitter_id for user in users]
        new_users = [User(friend_ids=[], twitter_id=id) for id in twitter_ids
                     if id not in existing_ids]
        db.session.add_all(new_users)
        db.session.commit()
