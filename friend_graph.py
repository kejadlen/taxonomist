import networkx as nx

from user import User


class FriendGraph:
    def __init__(self, user):
        self.user = user
        self.friends = User.query.filter(
            User.twitter_id.in_(self.user.friend_ids)
        ).all()
        self.graph = user.graph

    def cliques(self, k=3, cliques=None):
        friends = {friend.twitter_id: friend for friend in self.friends}
        cliques = list(nx.k_clique_communities(self.graph, k, cliques))
        return [[friends[id] for id in clique] for clique in cliques]
