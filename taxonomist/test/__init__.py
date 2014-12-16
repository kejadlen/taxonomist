import unittest

from sqlalchemy import create_engine

import taxonomist.twitter as twitter


class TestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine('postgresql://localhost/test', echo=False)
        cls.connection = cls.engine.connect()
        cls.transaction = cls.connection.begin()

        twitter.init_sql(cls.connection)

    @classmethod
    def tearDown(cls):
        twitter.Session.close()
        cls.transaction.rollback()
        cls.connection.close()
