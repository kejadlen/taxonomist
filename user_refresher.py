from itertools import izip_longest

import db
from twitter import Twitter
from user import User


class UserRefresher:
    def __init__(self, user, twitter=None):
        self.user = user
        self.twitter = twitter or user.twitter

    def run(self, hydrate=False, refresh_stale=False):
        if not self.user.is_stale:
            self.refresh_friends()

        if hydrate:
            self.hydrate_friends()

        if refresh_stale:
            self.refresh_stale_friends()

    def refresh_friends(self):
        ids, _ = self.twitter.friends_ids(self.user.twitter_id)
        self.user.friend_ids = ids
        db.session.commit()

    def hydrate_friends(self):
        named_friends = self.user.friends.filter(User.screen_name.isnot(None))
        named_friend_ids = [friend.twitter_id for friend in named_friends]
        dehydrated_user_ids = [id
                               for id in self.user.friend_ids
                               if id not in named_friend_ids]
        self.hydrate_users(dehydrated_user_ids)

    def refresh_stale_friends(self):
        for friend in self.user.stale_friends:
            twitter = friend.twitter or self.twitter
            self.__class__(friend, twitter).refresh_friends()

    def hydrate_users(self, user_ids):
        if not user_ids:
            return

        for chunk in izip_longest(*([iter(user_ids)] *
                                    Twitter.USERS_LOOKUP_CHUNK_SIZE)):
            self.hydrate_chunk(chunk)

    def hydrate_chunk(self, chunk):
        ids = [id for id in chunk if id is not None]
        profiles, _ = self.twitter.users_lookup(ids)
        for profile in profiles:
            user = User.query.filter(User.twitter_id == profile['id']).scalar()
            if user:
                user.screen_name = profile['screen_name']
            else:
                db.session.add(User(profile['id'], profile['screen_name']))
        db.session.commit()
