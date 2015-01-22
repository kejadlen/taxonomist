from threading import Thread

from .. import db
from ..models import interaction as interaction
from ..models.user import User
from .fetch_friends import FetchFriends
from .hydrate_users import HydrateUsers
from .update_interactions import UpdateInteractions
from .update_lists import UpdateLists


class UpdateUser:
    def __init__(self, user):
        self.user = user
        self.twitter = self.user.twitter

        self.fetch_friends = FetchFriends(self.twitter)
        self.hydrate_users = HydrateUsers(self.twitter)
        self.update_lists = UpdateLists(self.twitter)
        self.interaction_updater = UpdateInteractions(self.twitter)

    def run(self):
        self.update_self()

        threads = []

        threads.append(self.async(self.fetch_friends.run,
                                  *self.user.friend_ids, depth=2))
        threads.append(self.async(self.hydrate_users.run,
                                  *self.user.friend_ids))

        for i in [interaction.Mention, interaction.Favorite, interaction.DM]:
            threads.append(self.async(self.interaction_updater.run,
                                      i, self.user.id))

        for thread in threads:
            thread.join()

    def update_self(self):
        threads = []
        threads.append(self.async(self.fetch_friends.run,
                                  self.user.twitter_id, force=True))
        threads.append(self.async(self.hydrate_users.run,
                                  self.user.twitter_id, force=True))
        threads.append(self.async(self.update_lists.run, self.user.id))
        for thread in threads:
            thread.join()

        # Not sure if this refresh is needed? The above happens in separate
        # threads, so I don't know if this session knows about it.
        db.session.refresh(self.user)

    def async(self, task, *args, **kwargs):
        thread = Thread(target=task, args=args, kwargs=kwargs)
        thread.daemon = True
        thread.start()
        return thread
