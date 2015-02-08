from . import TestCase

from .. import db
from ..models.user import User


class TestDB(TestCase):
    def test_db(self):
        """ Verify that the test db is working as expected."""
        user = User(twitter_id=1, friend_ids=[])

        db.session.add(user)
        self.assertIsNone(user.id)

        db.session.commit()
        self.assertIsNotNone(user.id)
