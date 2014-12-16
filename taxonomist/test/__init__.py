import unittest

from sqlalchemy import create_engine

import taxonomist.twitter as twitter


class TestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('postgresql://localhost/test', echo=False)
        cls.connection = cls.engine.connect()
        cls.transaction = cls.connection.begin()

        twitter.init(cls.connection)

    @classmethod
    def tearDownClass(cls):
        twitter.Session.remove()
        cls.transaction.rollback()
        cls.connection.close()

    def setUp(self):
        self.transaction = self.connection.begin_nested()

    def tearDown(self):
        self.transaction.rollback()
