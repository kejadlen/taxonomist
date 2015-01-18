from datetime import datetime
from itertools import izip_longest

from . import Task
from .. import db
from ..models.user import User
from ..twitter import retry_rate_limited


class HydrateUsers(Task):
    def run(self, *user_ids):
        self.logger.info('%s(%d)', self.__class__.__name__, len(user_ids))

        if not user_ids:
            return

        users = User.query.filter(User.id.in_(user_ids))
        for chunk in izip_longest(*([iter(users)] *
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
