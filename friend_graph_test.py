import unittest

import networkx as nx

import db
from user import User
from friend_graph import FriendGraph
from test import TestCase


class TestFriendGraph(TestCase):
    def setUp(self):
        super(TestFriendGraph, self).setUp()

        # Pre-populate a graph to analyze.
        graph = nx.karate_club_graph()
        for node in graph.nodes():
            user = User(node)
            user.friend_ids = graph[node].keys()
            db.session.add(user)
        db.session.commit()

    def test_init_graph(self):
        user = User.query.filter(User.twitter_id == 0).scalar()
        friend_ids = [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 17, 19, 21, 31]
        self.assertEqual(user.friend_ids, friend_ids)

    def test_cliques(self):
        user = User.query.filter(User.twitter_id == 0).scalar()
        friend_graph = FriendGraph(user)

        cliques = friend_graph.cliques(k=3)
        self.assertEqual(cliques[0],
                         frozenset([0, 1, 2, 3, 32, 7, 8, 12, 13, 17, 19, 21]))

        cliques = friend_graph.cliques(k=4)
        self.assertEqual(cliques[0], frozenset([0, 1, 2, 3, 7, 13]))
