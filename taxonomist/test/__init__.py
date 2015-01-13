import os
import unittest

from sqlalchemy import create_engine

from .. import db
from ..models.user import User


class TestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('postgresql://localhost/test', echo=False)
        cls.connection = cls.engine.connect()
        cls.transaction = cls.connection.begin()

        db.init(cls.connection)

    @classmethod
    def tearDownClass(cls):
        db.Session.remove()
        cls.transaction.rollback()
        cls.connection.close()

    def setUp(self):
        self.transaction = self.connection.begin_nested()

        oauth_token = os.environ['TWITTER_ACCESS_TOKEN']
        oauth_token_secret = os.environ['TWITTER_ACCESS_TOKEN_SECRET']
        self.user = User(twitter_id=715073,
                         oauth_token=oauth_token,
                         oauth_token_secret=oauth_token_secret)
        db.Session.add(self.user)
        db.Session.commit()

    def tearDown(self):
        self.transaction.rollback()
