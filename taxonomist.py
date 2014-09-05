from flask import g, redirect, render_template, request, session, url_for
from flask import Flask

import db
from friend_updater import FriendUpdater
from twitter import Twitter
from user import User

app = Flask(__name__)
app.secret_key = "$zpWg$Mne7uj8eag"

@app.teardown_appcontext
def shutdown_session(exception=None):
    db.session.remove()

@app.route("/")
def index():
    user_id = session.get("user_id")
    template = "index.html" if user_id else "signin.html"
    return render_template(template)

@app.route("/signin")
def signin():
    request_token = Twitter.request_token()

    session["oauth_token"] = request_token.get("oauth_token")
    session["oauth_token_secret"] = request_token.get("oauth_token_secret")

    return redirect("https://api.twitter.com/oauth/authenticate?oauth_token=%s" % session['oauth_token'])

@app.route("/signout")
def signout():
    session.pop("user_id")
    return redirect(url_for("index"))

@app.route("/callback")
def callback():
    oauth_token = session.pop("oauth_token")
    oauth_token_secret = session.pop("oauth_token_secret")
    oauth_verifier = request.args.get("oauth_verifier")

    access_token = Twitter.access_token(oauth_token, oauth_token_secret, oauth_verifier)

    oauth_token = access_token.get("oauth_token")
    oauth_token_secret = access_token.get("oauth_token_secret")
    user_id = access_token.get("user_id")
    screen_name = access_token.get("screen_name")

    user = User.query.filter(User.twitter_id == user_id).first()
    if not user:
        user = User(user_id, screen_name)
        user.oauth_token = oauth_token
        user.oauth_token_secret = oauth_token_secret
        db.session.add(user)
        db.session.commit()
    session["user_id"] = user.id

    return redirect(url_for("index"))

@app.route("/update_friends")
def update_friends():
    user_id = session.get('user_id')
    if not user_id:
        abort(401)

    user = User.query.get(user_id)
    friend_updater = FriendUpdater(user.twitter)
    friend_updater.update(user)

    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(debug=True)
