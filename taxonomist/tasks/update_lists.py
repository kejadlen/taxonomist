from datetime import datetime
import logging

from . import Task
from ..models.list import List
from ..models.user import User
from ..twitter import retry_rate_limited
from .. import db


class UpdateLists(Task):
    def run(self, user_id):
        self.logger.info('%s(%d)', self.__class__.__name__, user_id)

        user = User.query.get(user_id)

        self.update_lists(user)
        for l in user.lists:
            self.update_members(l)

    def update_lists(self, user):
        lookup = {l.list_id: l for l in user.lists}
        for raw in self.fetch_cursored(self.twitter.lists_ownerships,
                                       'lists', user_id=user.twitter_id):
            l = lookup.get(raw['id'])
            if not l:
                l = List(list_id=raw['id'])
                user.lists.append(l)
            l.raw = raw
        db.session.commit()

    def update_members(self, l):
        members = self.fetch_cursored(self.twitter.lists_members,
                                      'users', list_id=l.list_id)
        member_ids = [member['id'] for member in members]

        # Update list
        l.member_ids = member_ids
        l.fetched_at = datetime.now().isoformat()
        db.session.commit()

        if not member_ids:
            return

        # Update users
        users = User.query.filter(User.twitter_id.in_(member_ids))
        lookup = {user.twitter_id: user
                  for user in users}
        for member in members:
            user = lookup.get(member['id'])
            if not user:
                user = User(twitter_id=member['id'])
                db.session.add(user)
            user.raw = member

        db.session.commit()

    @retry_rate_limited
    def fetch_cursored(self, endpoint, key, **params):
        cursor = -1
        data = []

        while True:
            self.logger.debug("Fetching %s with cursor %d",
                              endpoint.__name__, cursor)

            response = endpoint(**params)
            data.extend(response[key])
            cursor = response['next_cursor']

            if not cursor:
                break

        return data
