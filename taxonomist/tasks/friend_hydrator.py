from itertools import izip_longest

from .. import db
from ..twitter import retry_rate_limited


class FriendHydrator:
    def __init__(self, twitter):
        self.twitter = twitter

    def run(self, *users):
        for chunk in izip_longest(*([iter(users)] *
                                    self.twitter.USERS_LOOKUP_CHUNK_SIZE)):
            lookup = {user.twitter_id: user for user in self.users}
            profiles = self.fetch(lookup.keys())
            for profile in profiles:
                lookup[profile['id']].raw = profile

        db.session.commit()

    @retry_rate_limited
    def fetch(self, ids):
        return self.twitter.users_lookup(ids)
