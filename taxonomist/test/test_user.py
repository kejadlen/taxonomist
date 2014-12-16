from taxonomist.test import TestCase

from taxonomist.twitter import Session
from taxonomist.twitter.user import User


class TestUser(TestCase):
    def test_test_db(self):
        """ Verify that the test db is working as expected."""
        user = User(12345)
        self.assertIsNone(user.id)

        Session.add(user)
        Session.commit()

        self.assertIsNotNone(user.id)
