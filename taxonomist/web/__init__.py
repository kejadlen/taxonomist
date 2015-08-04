from flask import Flask, g, render_template, session
from networkx.readwrite import json_graph
import json
import networkx as nx
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


@app.route("/friend_graph.json")
def friend_graph():
    if g.user:
        data = json_graph.node_link_data(g.user.friend_graph)
    else:
        graph = nx.karate_club_graph()
        for node in graph.nodes():
            graph.node[node]["id"] = node
        data = json_graph.node_link_data(graph)
    return json.dumps(data)


@app.route("/friends.json")
def friends():
    if g.user:
        data = json_graph.node_link_data(g.user.friend_graph)
    else:
        graph = nx.karate_club_graph()
        for node in graph.nodes():
            graph.node[node]["id"] = node
        data = json_graph.node_link_data(graph)
    return json.dumps(data)
