from datetime import datetime

from celery import Celery

from twitter import RateLimitedError
from friends_refresher import FriendsRefresher

app = Celery('tasks', backend='redis://localhost', broker='redis://localhost')


@app.task(bind=True, acks_late=True, max_retries=None)
def refresh_friends(self, user):
    try:
        FriendsRefresher(user).run()
    except RateLimitedError as exc:
        delta = exc.rate_limit_reset - datetime.now()
        countdown = delta.total_seconds() + 1
        raise self.retry(exc=exc, countdown=countdown)
