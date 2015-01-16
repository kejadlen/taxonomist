import os

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker

Base = declarative_base()


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
