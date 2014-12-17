import unittest

from sqlalchemy import create_engine

import taxonomist.db as db


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

    def tearDown(self):
        self.transaction.rollback()
