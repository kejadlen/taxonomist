from flask import Flask, g, render_template, session
import os

from .. import db
from ..models.user import User

app = Flask(__name__, static_url_path='')

from . import auth

app.secret_key = os.environ["FLASK_SECRET"]


@app.before_request
def before_request():
    db.init()

    g.user = None
    if 'user_id' in session:
        g.user = User.query.get(session['user_id'])


@app.teardown_appcontext
def shutdown_session(exception=None):
    db.session.remove()


@app.route("/")
def index():
    return render_template("index.html")
