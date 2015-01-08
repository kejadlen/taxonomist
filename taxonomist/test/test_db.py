from taxonomist.test import TestCase

from taxonomist.db import Session
from taxonomist.models.user import User


class TestDB(TestCase):
    def test_db(self):
        """ Verify that the test db is working as expected."""
        user = User(twitter_id=1)

        Session.add(user)
        self.assertIsNone(user.id)

        Session.commit()
        self.assertIsNotNone(user.id)
