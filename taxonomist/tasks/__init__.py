from datetime import datetime, timedelta
import logging


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
