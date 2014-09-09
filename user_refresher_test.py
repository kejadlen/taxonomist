import datetime
import unittest

from mock import call, Mock
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

import db
from user import User
from user_refresher import UserRefresher


class TestUserRefresher(unittest.TestCase):
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
        self.user_refresher = UserRefresher(self.user, self.twitter)

        db.session.add(self.user)
        db.session.commit()

    def tearDown(self):
        db.session.close()
        self.transaction.rollback()

        db.session = self.original_session
        db.Base.query = db.session.query_property()

    def test_is_stale(self):
        self.user.updated_at = None
        self.assertTrue(UserRefresher.is_stale(self.user))

        one_day = datetime.timedelta(days=1)
        base_updated_at = datetime.datetime.now() - UserRefresher.STALE

        self.user.updated_at = base_updated_at - one_day
        self.assertTrue(UserRefresher.is_stale(self.user))

        self.user.updated_at = base_updated_at + one_day
        self.assertFalse(UserRefresher.is_stale(self.user))

    def test_refresh_friends(self):
        ids = range(1, 6)
        self.twitter.friends_ids = Mock(return_value=(ids, None))

        self.user_refresher.refresh_friends()

        user = User.query.get(self.user.id)
        self.assertEqual(user.friend_ids, ids)

    def test_hydrate_existing_friends(self):
        self.user.friend_ids = range(1, 6)
        db.session.add_all([User(1, 'Alice'), User(3), User(5, 'Bob')])
        db.session.commit()

        profiles = [{'id': 2, 'screen_name': 'Eve'},
                    {'id': 3, 'screen_name': 'Mallory'},
                    {'id': 4, 'screen_name': 'Trent'}]
        self.twitter.users_lookup = Mock(return_value=(profiles, None))

        ids = range(1, 6)
        self.user_refresher.hydrate_friends()

        self.twitter.users_lookup.assert_called_with([2, 3, 4])
        for profile in profiles:
            user = User.query.filter(User.twitter_id == profile['id']).scalar()
            self.assertEqual(user.screen_name, profile['screen_name'])

    def test_hydrate_lots_of_friends(self):
        self.user.friend_ids = range(1, 151)
        db.session.commit()

        def side_effect(ids):
            profiles = [{'id': id, 'screen_name': str(id)} for id in ids]
            return (profiles, None)
        self.twitter.users_lookup = Mock(side_effect=side_effect)

        self.user_refresher.hydrate_friends()

        self.assertEqual(self.twitter.users_lookup.call_args_list,
                         [call(range(1, 101)), call(range(101, 151))])
