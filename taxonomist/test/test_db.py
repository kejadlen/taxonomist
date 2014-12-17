from taxonomist.test import TestCase

from taxonomist.db import Session
from taxonomist.models.user import User


class TestDB(TestCase):
    def test_db(self):
        """ Verify that the test db is working as expected."""
        user = User(12345)
        self.assertIsNone(user.id)

        Session.add(user)
        Session.commit()

        self.assertIsNotNone(user.id)
