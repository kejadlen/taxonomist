from datetime import datetime, timedelta

from test import TestCase
from user import User

class TestUser(TestCase):
    def setUp(self):
        super(TestUser, self).setUp()

        self.user = User(12345)

    def test_is_stale(self):
        self.user.updated_at = None
        self.assertTrue(self.user.is_stale)

        one_day = timedelta(days=1)
        base_updated_at = datetime.now() - User.STALE

        self.user.updated_at = base_updated_at - one_day
        self.assertTrue(self.user.is_stale)

        self.user.updated_at = base_updated_at + one_day
        self.assertFalse(self.user.is_stale)
