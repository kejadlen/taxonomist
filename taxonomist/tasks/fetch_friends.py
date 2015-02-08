from datetime import datetime

import requests

from . import Task
from .. import db
from ..models.user import User
from ..twitter import retry_rate_limited


class FetchFriends(Task):
    def run(self, *twitter_ids, force=False):
        self.logger.info('%s(%s)', self.__class__.__name__, len(twitter_ids))

        if not twitter_ids:
            return

        self.create_users(twitter_ids)
        users = User.query.filter(User.twitter_id.in_(twitter_ids))
        stale_users = [user for user in users
                       if not force and self.is_stale(user)]

        for user in stale_users:
            self.logger.info('%s(%s)',
                             self.__class__.__name__, user)

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
        try:
            return self.twitter.friends_ids(id)
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == requests.codes.unauthorized:
                self.logger.warn('Skipping fetching friends for %d (401)', id)
                return []
            else:
                raise
