import os

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker

Base = declarative_base()


def __repr__(self):
    attrs = self.__attrs__
    attrs = ['{}={}'.format(attr, getattr(self, attr)) for attr in attrs]
    attrs = ', '.join(attrs)
    return '{}({})'.format(self.__class__.__name__, attrs)

Base.__repr__ = __repr__


def init(engine=None):
    global Session, session

    engine = engine or create_engine(os.environ['DATABASE'], echo=False)
    session_factory = sessionmaker(autocommit=False,
                                   autoflush=False,
                                   bind=engine)

    Session = scoped_session(session_factory)
    session = Session()

    Base.query = Session.query_property()
    Base.metadata.create_all(engine)
