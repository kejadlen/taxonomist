import unittest

from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

import taxonomist.twitter as twitter

class TestCase(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine('postgresql://localhost/test', echo=True)
        self.connection = self.engine.connect()
        self.transaction = self.connection.begin()

        twitter.init_sql(self.connection)

    def tearDown(self):
        twitter.Session.close()
        self.transaction.rollback()
        self.connection.close()
