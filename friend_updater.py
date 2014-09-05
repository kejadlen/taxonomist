import datetime

class FriendsUpdater:
    STALE = datetime.timedelta(weeks=4)

    def __init__(self, twitter):
        self.twitter = twitter

    @classmethod
    def is_stale(cls, user):
        return user.created_at is None or datetime.datetime.now() - user.created_at > cls.STALE

import unittest
from collections import namedtuple

MockUser = namedtuple('MockUser', 'created_at')

class TestFriendUpdater(unittest.TestCase):
    def test_is_stale(self):
        user = MockUser(created_at=None)
        self.assertTrue(FriendsUpdater.is_stale(user))

        one_day = datetime.timedelta(days=1)
        base_created_at = datetime.datetime.now() - FriendsUpdater.STALE

        created_at = base_created_at - one_day
        user = MockUser(created_at=created_at)
        self.assertTrue(FriendsUpdater.is_stale(user))

        created_at = base_created_at + one_day
        user = MockUser(created_at=created_at)
        self.assertFalse(FriendsUpdater.is_stale(user))

if __name__ == '__main__':
    unittest.main()
