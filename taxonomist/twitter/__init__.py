from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker

Session = scoped_session(sessionmaker(autocommit=False, autoflush=False))
Base = declarative_base()

def init_sql(engine):
    Session.configure(bind=engine)
    Base.metadata.bind = engine
    Base.query = Session.query_property()

    Base.metadata.create_all(engine)
