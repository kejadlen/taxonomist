import unittest

import networkx as nx

import db
from cliques import CPM, SLPA
from user import User


class TestCPM(unittest.TestCase):
    def test_cliques(self):
        graph = nx.karate_club_graph()
        cpm = CPM(graph)

        cliques = cpm.cliques()
        self.assertEqual(cliques[-1], frozenset([0, 16, 4, 5, 6, 10]))

        cliques = cpm.cliques(k=4)
        self.assertEqual(cliques[0], frozenset([0, 1, 2, 3, 7, 13]))
