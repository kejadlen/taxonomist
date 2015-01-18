from datetime import datetime, timedelta
from threading import Thread

from .. import db
from ..models import interaction as interaction
from ..models.user import User
from fetch_friends import FetchFriends
from hydrate_users import HydrateUsers
from update_interactions import UpdateInteractions


class UpdateUser:
    STALE = timedelta(weeks=1)

    # TODO Add jitter
    @classmethod
    def is_stale(cls, type, user):
        key = type.__name__

        if not key in user.fetched_ats:
            return True

        fetched_at = datetime.strptime(user.fetched_ats[key],
                                       '%Y-%m-%dT%H:%M:%S.%f')
        return datetime.now() - fetched_at > cls.STALE

    def __init__(self, user):
        self.user = user
        self.twitter = self.user.twitter

        self.fetch_friends = FetchFriends(self.twitter)
        self.hydrate_users = HydrateUsers(self.twitter)
        self.interaction_updater = UpdateInteractions(self.twitter)

    def run(self):
        self.update_self()

        threads = []

        stale_friend_ids = [friend.id for friend in self.user.friends
                            if self.is_stale(HydrateUsers, friend)]
        threads.append(self.async(self.fetch_friends.run, *stale_friend_ids))
        threads.append(self.async(self.hydrate_users.run, *stale_friend_ids))

        for i in [interaction.Mention, interaction.Favorite, interaction.DM]:
            threads.append(self.async(self.interaction_updater.run,
                                      i, self.user.id))

        for thread in threads:
            thread.join()

    def update_self(self):
        for task in [FetchFriends, HydrateUsers]:
            if self.is_stale(task, self.user):
                task(self.twitter).run(self.user.id)

        self.create_users()

    def create_users(self):
        '''Since we need two levels of friendships for analysis, friends of the
        target user need to exist in the DB to store their friend_ids.
        '''
        existing_ids = [friend.twitter_id for friend in self.user.friends]
        new_users = [User(twitter_id=id) for id in self.user.friend_ids
                     if id not in existing_ids]
        db.session.add_all(new_users)
        db.session.commit()

    def async(self, task, *args):
        thread = Thread(target=task, args=args)
        thread.daemon = True
        thread.start()
        return thread
