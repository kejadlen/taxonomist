import unittest

from mock import call, Mock

import db
from test import TestCase
from user import User
from user_refresher import UserRefresher


class TestUserRefresher(TestCase):
    def setUp(self):
        super(TestUserRefresher, self).setUp()

        self.user = User(12345)
        self.twitter = Mock()
        self.user_refresher = UserRefresher(self.user, self.twitter)

        db.session.add(self.user)
        db.session.commit()

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

        self.twitter.users_lookup.assert_called_with([3, 2, 4])
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
