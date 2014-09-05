import datetime

import db


class FriendUpdater:
    STALE = datetime.timedelta(weeks=4)

    def __init__(self, twitter):
        self.twitter = twitter

    def update(user, hydrate_friends=False):
        if is_stale(user):
            self.update_friends(user)

    def update_friends(self, user):
        ids, _ = self.twitter.friends_ids(user.twitter_id)
        user.friend_ids = ids
        db.session.commit()

    @classmethod
    def is_stale(cls, user):
        return user.created_at is None or datetime.datetime.now() - user.created_at > cls.STALE

import unittest

from mock import Mock
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

import db
from user import User


class TestFriendUpdater(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('postgresql://localhost/taxonomist_test',
                                   echo=True)
        cls.connection = cls.engine.connect()

    @classmethod
    def tearDownClass(cls):
        cls.connection.close()

    def setUp(self):
        self.transaction = self.connection.begin()
        self.session = scoped_session(sessionmaker(autocommit=False,
                                                   autoflush=False,
                                                   bind=self.connection))
        db.Base.query = self.session.query_property()
        db.Base.metadata.create_all(bind=self.connection)

        self.user = User(12345)
        self.twitter = Mock()
        self.friend_updater = FriendUpdater(self.twitter)

    def tearDown(self):
        self.session.close()
        self.transaction.rollback()

        db.Base.query = db.session.query_property()

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
        ids = [1, 2, 3, 4, 5]
        self.twitter.friends_ids = Mock(return_value=(ids, None))

        self.friend_updater.update_friends(self.user)
        self.assertEqual(self.user.friend_ids, 1)
