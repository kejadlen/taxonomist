from datetime import datetime

from . import Task
from .. import db
from ..models.user import User
from ..twitter import retry_rate_limited


class FetchFriends(Task):
    def run(self, *user_ids):
        self.logger.info('%s(%d)', self.__class__.__name__, len(user_ids))

        if not user_ids:
            return

        users = User.query.filter(User.id.in_(user_ids))
        for user in users:
            # We only do a single fetch to get the first 5000 friends, since I
            # don't want to analyze accounts that just auto-follow a ton of
            # people on Twitter.
            ids = self.fetch(user.twitter_id)
            user.friend_ids = ids

            fetched_at = datetime.now().isoformat()
            user.fetched_ats[self.__class__.__name__] = fetched_at

            db.session.commit()

    @retry_rate_limited
    def fetch(self, id):
        return self.twitter.friends_ids(id)
