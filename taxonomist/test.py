import unittest

from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

import db

class TestCase(unittest.TestCase):
    def setUp(self):
        self.original_session = db.session

        self.engine = create_engine('postgresql://localhost/test',
                                    echo=True)
        self.connection = self.engine.connect()
        self.transaction = self.connection.begin()

        db.session = scoped_session(sessionmaker(autocommit=False,
                                                 autoflush=False,
                                                 bind=self.connection))
        db.Base.query = db.session.query_property()
        db.Base.metadata.create_all(bind=self.connection)

    def tearDown(self):
        db.session.close()
        self.transaction.rollback()
        self.connection.close()

        db.session = self.original_session
        db.Base.query = db.session.query_property()
