import datetime

class FriendUpdater:
    STALE = datetime.timedelta(weeks=4)

    def __init__(self, twitter):
        self.twitter = twitter

    def update(user, hydrate_friends=False):
        if is_stale(user):
            self.update_friends(user)

    def update_friends(self, user):
        response = twitter.friends_ids(user.twitter_id)
        response.json()

    @classmethod
    def is_stale(cls, user):
        return user.created_at is None or datetime.datetime.now() - user.created_at > cls.STALE

import unittest
from collections import namedtuple

from mock import Mock

class TestFriendUpdater(unittest.TestCase):
    def setUp(self):
        self.user = Mock()
        self.twitter = Mock()
        self.friend_updater = FriendUpdater(self.twitter)

    def test_is_stale(self):
        self.user.created_at = None
        self.assertTrue(FriendUpdater.is_stale(self.user))

        one_day = datetime.timedelta(days=1)
        base_created_at = datetime.datetime.now() - FriendUpdater.STALE

        self.user.created_at = base_created_at - one_day
        self.assertTrue(FriendUpdater.is_stale(self.user))

        self.user.created_at = base_created_at + one_day
        self.assertFalse(FriendUpdater.is_stale(self.user))

    def test_update_friends(self):
        pass
