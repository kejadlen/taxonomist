import datetime
from itertools import izip_longest

import db


class FriendUpdater:
    STALE = datetime.timedelta(weeks=4)

    def __init__(self, twitter):
        self.twitter = twitter

    def update(user, hydrate_friends=False):
        if is_stale(user):
            self.update_friends(user)

        if hydrate_friends:
            self.hydrate_friends(user.friend_ids)

    def update_friends(self, user):
        ids, _ = self.twitter.friends_ids(user.twitter_id)
        user.friend_ids = ids
        db.session.commit()

    def hydrate_friends(self, friend_ids):
        users_with_names = User.query.filter(User.twitter_id.in_(friend_ids),
                                             User.screen_name != None)
        user_ids = [id for (id, ) in users_with_names.values(User.twitter_id)]
        dehydrated_ids = [id for id in friend_ids if id not in user_ids]

        for ids in izip_longest(*([iter(dehydrated_ids)] * 100)):
            ids = [id for id in ids if id is not None]
            profiles, _ = self.twitter.users_lookup(ids)
            for profile in profiles:
                user = User.query.filter(User.twitter_id == profile['id']).first()
                if user is None:
                    db.session.add(User(profile['id'], profile['screen_name']))
                else:
                    user.screen_name = profile['screen_name']
        db.session.commit()

    @classmethod
    def is_stale(cls, user):
        return user.created_at is None or datetime.datetime.now() - user.created_at > cls.STALE

import unittest

from mock import call, Mock
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
        self.original_session = db.session

        self.transaction = self.connection.begin()
        db.session = scoped_session(sessionmaker(autocommit=False,
                                                   autoflush=False,
                                                   bind=self.connection))
        db.Base.query = db.session.query_property()
        db.Base.metadata.create_all(bind=self.connection)

        self.user = User(12345)
        self.twitter = Mock()
        self.friend_updater = FriendUpdater(self.twitter)

    def tearDown(self):
        db.session.close()
        self.transaction.rollback()

        db.session = self.original_session
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
        db.session.add(self.user)
        db.session.commit()

        ids = range(1, 6)
        self.twitter.friends_ids = Mock(return_value=(ids, None))

        self.friend_updater.update_friends(self.user)

        user = User.query.get(self.user.id)
        self.assertEqual(user.friend_ids, ids)

    def test_hydrate_existing_friends(self):
        db.session.add_all([User(1, "Alice"), User(3), User(5, "Bob")])
        db.session.commit()

        profiles = [{'id':2, 'screen_name':"Eve"},
                    {'id':3, 'screen_name':"Mallory"},
                    {'id':4, 'screen_name':"Trent"}]
        mock = Mock(return_value=(profiles, None))
        self.twitter.users_lookup = mock

        ids = range(1, 6)
        self.friend_updater.hydrate_friends(ids)

        mock.assert_called_with([2, 3, 4])

        for profile in profiles:
            user = User.query.filter(User.twitter_id == profile['id']).first()
            self.assertEqual(user.screen_name, profile['screen_name'])

    def test_hydrate_lots_of_friends(self):
        mock = Mock(return_value=([], None))
        self.twitter.users_lookup = mock

        ids = range(1, 151)
        self.friend_updater.hydrate_friends(ids)

        self.assertEqual(mock.call_args_list,
                         [call(range(1, 101)), call(range(101, 151))])
