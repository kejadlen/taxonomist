from .. import db
from ..twitter import retry_rate_limited


class GraphFetcher:
    def __init__(self, twitter):
        self.twitter = twitter

    def run(self, *users):
        for user in users:
            ids = self.fetch(user.twitter_id)
            user.friend_ids = ids
        db.session.commit()

    @retry_rate_limited
    def fetch(self, id):
        return self.twitter.friends_ids(id)
