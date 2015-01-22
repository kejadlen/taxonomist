from datetime import datetime
from itertools import zip_longest

from . import Task
from .. import db
from ..models.user import User
from ..twitter import retry_rate_limited


class HydrateUsers(Task):
    def run(self, *twitter_ids, force=False):
        self.logger.info('%s(%s)', self.__class__.__name__, len(twitter_ids))

        self.create_users(twitter_ids)
        users = User.query.filter(User.twitter_id.in_(twitter_ids))
        stale_users = [user for user in users
                       if not force and self.is_stale(user)]

        for chunk in zip_longest(*([iter(stale_users)] *
                                   self.twitter.USERS_LOOKUP_CHUNK_SIZE)):
            lookup = {user.twitter_id: user for user in chunk if user}
            profiles = self.fetch(lookup.keys())
            for profile in profiles:
                user = lookup[profile['id']]

                user.raw = profile

                fetched_at = datetime.now().isoformat()
                user.fetched_ats[self.__class__.__name__] = fetched_at

                db.session.commit()

    @retry_rate_limited
    def fetch(self, ids):
        return self.twitter.users_lookup(ids)
