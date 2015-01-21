import random
from collections import defaultdict, Counter


class SLPA:
    '''An implementation of the Speaker-listener Label Propagation Algorithm
    described in http://arxiv.org/pdf/1109.5720.pdf.
    '''
    def __init__(self, graph):
        self.graph = graph
        self.memory = {}

    def cliques(self, t=None, r=0.5):
        if t or not self.memory:
            self.explore(t)

        # Stage 3: post-processing
        cliques = defaultdict(list)
        for node in self.graph.nodes():
            memory = self.memory[node]
            counter = Counter(memory)
            for clique in [label
                           for label in counter.keys()
                           if counter[label] > len(memory) * r]:
                cliques[clique].append(node)

        return cliques

    def explore(self, t=None):
        t = t or 20

        # Stage 1: initialization
        nodes = self.graph.nodes()
        self.memory = {node:[node] for node in nodes}

        # Stage 2: evolution
        for _ in range(t):
            random.shuffle(nodes)
            for listener in nodes:
                neighbors = self.graph.neighbors(listener)
                if neighbors:
                    labels = [random.choice(self.memory[neighbor])
                              for neighbor in neighbors]
                    most_popular, _ = Counter(labels).most_common(1)[0]
                    self.memory[listener].append(most_popular)
