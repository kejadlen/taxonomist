from datetime import datetime

from .. import db
from ..twitter import retry_rate_limited


class GraphFetcher:
    def __init__(self, twitter):
        self.twitter = twitter

    def run(self, *user_ids):
        users = User.query.filter(User.id.in_(user_ids))
        for user in users:
            print "GraphFetcher: {}".format(user)
            ids = self.fetch(user.twitter_id)
            user.friend_ids = ids

            fetched_at = datetime.now().isoformat()
            user.fetched_ats[self.__class__.__name__] = fetched_at

            db.session.commit()

    @retry_rate_limited
    def fetch(self, id):
        return self.twitter.friends_ids(id)
