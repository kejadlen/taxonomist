import datetime
import os

from sqlalchemy import BigInteger, Column, DateTime, Integer, String
from sqlalchemy import create_engine, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker

engine = create_engine(os.environ['DATABASE'], echo=True)
db_session = scoped_session(sessionmaker(autocommit=False,
                                         autoflush=False,
                                         bind=engine))

Base = declarative_base()
Base.query = db_session.query_property()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    twitter_id = Column(BigInteger, nullable=False, unique=True)
    screen_name = Column(String(32))
    friend_ids = Column(ARRAY(BigInteger))
    created_at = Column(DateTime, server_default=text('current_timestamp'))
    updated_at = Column(DateTime, onupdate=datetime.datetime.now)
    oauth_token = Column(String(255))
    oauth_token_secret = Column(String(255))

def init_db():
    Base.metadata.create_all(bind=engine)

from flask import g, redirect, render_template, request, session
from flask import Flask
from requests_oauthlib import OAuth1Session

app = Flask(__name__)

@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()

@app.route("/")
def index():
    # TODO Detect if signed in
    return app.send_static_file("index.html")

@app.route("/signin")
def signin():
    twitter = OAuth1Session(os.environ["API_KEY"],
                            os.environ["API_SECRET"],
                            callback_uri="http://127.0.0.1:5000/callback")

    fetch_response = twitter.fetch_request_token("https://api.twitter.com/oauth/request_token")
    oauth_token = fetch_response.get("oauth_token")
    oauth_token_secret = fetch_response.get("oauth_token_secret")

    session["oauth_token"] = oauth_token
    session["oauth_token_secret"] = oauth_token_secret
    return redirect("https://api.twitter.com/oauth/authenticate?oauth_token=%s" % oauth_token)

@app.route("/callback")
def callback():
    oauth_token = session.pop("oauth_token")
    oauth_token_secret = session.pop("oauth_token_secret")
    oauth_verifier = request.args.get("oauth_verifier")

    twitter = OAuth1Session(os.environ["API_KEY"],
                            os.environ["API_SECRET"],
                            resource_owner_key=oauth_token,
                            resource_owner_secret=oauth_token_secret,
                            verifier=oauth_verifier)

    oauth_tokens = twitter.fetch_access_token("https://api.twitter.com/oauth/access_token")
    oauth_token = oauth_tokens.get("oauth_token")
    oauth_token_secret = oauth_tokens.get("oauth_token_secret")
    user_id = oauth_tokens.get("user_id")
    screen_name = oauth_tokens.get("screen_name")

    # TODO Store in DB, set user in session

    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(debug=True)
