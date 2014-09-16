import db
from list import List


class ListRefresher:
    def __init__(self, user, twitter=None):
        self.user = user
        self.twitter = twitter or user.twitter

    def run(self):
        self.refresh_lists()
        self.update_lists([list for list in self.user.lists if list.is_stale])

    def refresh_lists(self):
        id = self.user.twitter_id
        cursor = -1
        while cursor:
            lists, cursor, response = self.twitter.lists_ownerships(id, cursor)
            for raw in lists:
                list = List.query.filter(List.twitter_id == raw['id']).scalar()
                if list:
                    list.name = raw['name']
                else:
                    db.session.add(List(raw))
        db.session.commit()

    def update_lists(self, lists):
        for list in lists:
            self.update_list(list)

    def update_list(self, list):
        id = list.twitter_id
        cursor = -1
        while cursor:
            members, cursor, response = self.twitter.lists_members(id, cursor)
            list.member_ids = [member['id'] for member in members]
        db.session.commit()
