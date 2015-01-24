import os
import unittest

from sqlalchemy import create_engine

from .. import db
from ..models.list import List
from ..models.user import User


class TestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('postgresql://localhost/test', echo=True)
        cls.connection = cls.engine.connect()

    @classmethod
    def tearDownClass(cls):
        cls.connection.close()

    def setUp(self):
        self.transaction = self.connection.begin_nested()

        db.init(self.connection)

        oauth_token = os.environ['TWITTER_ACCESS_TOKEN']
        oauth_token_secret = os.environ['TWITTER_ACCESS_TOKEN_SECRET']
        self.user = User(twitter_id=715073,
                         friend_ids=[],
                         oauth_token=oauth_token,
                         oauth_token_secret=oauth_token_secret)
        db.session.add(self.user)
        db.session.commit()

    def tearDown(self):
        self.transaction.rollback()
