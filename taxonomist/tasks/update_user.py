from datetime import datetime, timedelta
from threading import Event

from ..models.user import User
from ..twitter import retry_rate_limited
from twitter_task import TwitterTask
from .. import db


def is_stale(user):
    return user.updated_at is None or \
        datetime.now() - user.updated_at > timedelta(weeks=1)


class UpdateUser:
    def __init__(self, user):
        self.user = user
        self.twitter = self.user.twitter

        self.graph_fetcher = GraphFetcher(self.twitter)
        self.hydrator = FriendHydrator(self.twitter)

    def run(self):
        if is_stale(self.user):
            self.graph_fetcher.put(self.user.twitter_id)
            self.graph_fetcher.join()
            self.hydrator.put(self.user)

        existing_ids = [friend.twitter_id for friend in self.user.friends]
        new_users = [User(twitter_id=id) for id in self.user.friend_ids
                     if id not in existing_ids]
        db.Session.add_all(new_users)
        db.Session.commit()

        for user in self.user.friends:
            self.hydrator.put(user)
            self.graph_fetcher.put(user)
        self.hydrator.put(None)

        self.hydrator.join()
        self.graph_fetcher.join()


class GraphFetcher(TwitterTask):
    @retry_rate_limited
    def process(self, user):
        if not is_stale(user):
            return

        ids = self.twitter.friends_ids(user.twitter_id)
        User.query.filter_by(twitter_id=user.twitter_id).\
            update({'friend_ids': ids})
        db.Session.commit()


class FriendHydrator(TwitterTask):
    def __init__(self, twitter):
        super(FriendHydrator, self).__init__(twitter)

        self.users = []
        self.event = Event()
        self.event.clear()

    @retry_rate_limited
    def process(self, user):
        if user is None:
            chunk_size = 1
        else:
            chunk_size = self.twitter.USERS_LOOKUP_CHUNK_SIZE
            if is_stale(user):
                self.users.append(user)

        if len(self.users) >= chunk_size:
            ids = [user.twitter_id
                   for user in self.users[:chunk_size]
                   if user is not None]
            profiles = self.twitter.users_lookup(ids)
            for profile in profiles:
                User.query.filter_by(twitter_id=profile['id']).\
                    update({'raw': profile})
            db.Session.commit()
            self.users = self.users[chunk_size:]

        if user is None:
            self.event.set()

    def join(self):
        self.event.wait()
