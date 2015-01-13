from datetime import datetime
from time import sleep

from client import RateLimitError


def retry_rate_limited(f):
    def retry(*args, **kwargs):
        while True:
            try:
                f(*args, **kwargs)
            except RateLimitError as exc:
                delta = exc.rate_limit_reset - datetime.now()
                countdown = delta.total_seconds() + 1
                # TODO: Replace w/logger
                print "Rate limited, sleeping for %i seconds" % countdown
                sleep(countdown)
            return
    return retry
