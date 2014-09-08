import networkx as nx

from user import User


class FriendGraph:
    def __init__(self, user):
        self.user = user
        self.init_graph()

    def init_graph(self):
        self.graph = nx.Graph()

        self.graph.add_edges_from([(self.user.twitter_id, id)
                                   for id in self.user.friend_ids])
        for friend in User.query.filter(
            User.twitter_id.in_(self.user.friend_ids),
            User.friend_ids.isnot(None)
        ):
            edges = [(friend.twitter_id, friend_id)
                     for friend_id in friend.friend_ids]
            self.graph.add_edges_from(edges)

    def cliques(self, k=3):
        return list(nx.k_clique_communities(self.graph, k))
