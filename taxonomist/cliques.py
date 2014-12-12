import random
from collections import defaultdict, Counter

import networkx as nx


class CPM:
    def __init__(self, graph):
        self.graph = graph

    def cliques(self, k=3, cliques=None):
        return list(nx.k_clique_communities(self.graph, k, cliques))


class SLPA:
    def __init__(self, graph):
        self.graph = graph
        self.memory = {}

    def explore(self, t=None):
        t = t or 20
        nodes = self.graph.nodes()

        # Initialize memory
        self.memory = {node:[node] for node in nodes}

        for _ in range(t):
            random.shuffle(nodes)
            for listener in nodes:
                neighbors = self.graph.neighbors(listener)
                if neighbors:
                    labels = [random.choice(self.memory[neighbor])
                            for neighbor in neighbors]
                    most_popular, _ = Counter(labels).most_common(1)[0]
                    self.memory[listener].append(most_popular)

    def cliques(self, t=None, r=0.5):
        if t or not self.memory:
            self.explore(t)

        cliques = defaultdict(list)
        for node in self.graph.nodes():
            memory = self.memory[node]
            counter = Counter(memory)
            for clique in [label
                           for label in counter.keys()
                           if counter[label] > len(memory) * r]:
                cliques[clique].append(node)
        return cliques
