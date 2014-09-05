import datetime
from itertools import izip_longest

import db
from user import User


class FriendUpdater:
    STALE = datetime.timedelta(weeks=4)

    def __init__(self, twitter):
        self.twitter = twitter

    def update(self, user, hydrate_friends=False):
        if self.is_stale(user):
            self.update_friends(user)

        if self.hydrate_friends:
            self.hydrate_friends(user.friend_ids)

    def update_friends(self, user):
        ids, _ = self.twitter.friends_ids(user.twitter_id)
        user.friend_ids = ids
        db.session.commit()

    def hydrate_friends(self, friend_ids):
        # Only hydrate users that don't have names already in the DB.
        users_with_names = User.query.filter(User.twitter_id.in_(friend_ids),
                                             User.screen_name != None)
        user_ids = [id for (id, ) in users_with_names.values(User.twitter_id)]
        dehydrated_ids = [id for id in friend_ids if id not in user_ids]

        # Since users_lookup takes a maximum of 100 ids, we slice the
        # list of dehydrated ids into chunks of 100 to hydrate them.
        for ids in izip_longest(*([iter(dehydrated_ids)] * 100)):
            ids = [id for id in ids if id is not None]
            profiles, _ = self.twitter.users_lookup(ids)
            for profile in profiles:
                user = User.query.filter(User.twitter_id == profile['id']).first()
                if user:
                    user.screen_name = profile['screen_name']
                else:
                    db.session.add(User(profile['id'], profile['screen_name']))
        db.session.commit()

        users = User.query.filter(User.twitter_id.in_(friend_ids)).all()
        for user in users:
            self.update(user)

    @classmethod
    def is_stale(cls, user):
        return user.updated_at is None or datetime.datetime.now() - user.updated_at > cls.STALE
