import json
import os

import networkx as nx
from flask import g, redirect, render_template, request, session, url_for
from flask import Flask
from flask.ext.assets import Environment, Bundle
from networkx.readwrite import json_graph

import db
from user_refresher import UserRefresher
from twitter import Twitter
from user import User

app = Flask(__name__)
app.secret_key = os.environ['FLASK_SECRET']

assets = Environment(app)
assets.load_path = [os.path.join(os.path.dirname(__file__), 'bower_components')]
assets.register('js', Bundle('jquery/dist/jquery.min.js',
                             'bootstrap/dist/js/bootstrap.min.js',
                             'd3/d3.min.js'))
assets.register('css', Bundle('bootstrap/dist/css/bootstrap.min.css'))


@app.before_request
def before_request():
    g.user = None
    if 'user_id' in session:
        g.user = User.query.get(session['user_id'])


@app.teardown_appcontext
def shutdown_session(exception=None):
    db.session.remove()


@app.route('/')
def index():
    template = 'index.html' # if g.user else 'signin.html'
    return render_template(template)


@app.route('/signin')
def signin():
    request_token = Twitter.request_token()

    session['oauth_token'] = request_token.get('oauth_token')
    session['oauth_token_secret'] = request_token.get('oauth_token_secret')

    url = 'https://api.twitter.com/oauth/authenticate?oauth_token=%s'
    return redirect(url % session['oauth_token'])


@app.route('/signout')
def signout():
    session.pop('user_id', None)
    return redirect(url_for('index'))


@app.route('/callback')
def callback():
    oauth_token = session.pop('oauth_token')
    oauth_token_secret = session.pop('oauth_token_secret')
    oauth_verifier = request.args.get('oauth_verifier')

    access_token = Twitter.access_token(oauth_token,
                                        oauth_token_secret,
                                        oauth_verifier)

    oauth_token = access_token.get('oauth_token')
    oauth_token_secret = access_token.get('oauth_token_secret')
    user_id = access_token.get('user_id')
    screen_name = access_token.get('screen_name')

    user = User.query.filter(User.twitter_id == user_id).scalar()
    if not user:
        user = User(user_id, screen_name)
        user.oauth_token = oauth_token
        user.oauth_token_secret = oauth_token_secret
        db.session.add(user)
        db.session.commit()
    session['user_id'] = user.id

    return redirect(url_for('index'))


@app.route('/update_friends')
def update_friends():
    if not g.user:
        abort(401)

    user_refresher = UserRefresher(user)
    user_refresher.run(hydrate=True, refresh_stale=True)

    return redirect(url_for('index'))


@app.route('/friends.json')
def friends():
    graph = nx.karate_club_graph()
    for node in graph.nodes():
        graph.node[node]['screen_name'] = node
    data = json_graph.node_link_data(graph)
    data = json_graph.node_link_data(g.user.graph)
    return json.dumps(data)

if __name__ == '__main__':
    app.run(debug=True)
