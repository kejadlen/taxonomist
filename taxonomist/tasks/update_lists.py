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

        lists = self.fetch_and_create_lists(user)
        for l in lists:
            self.fetch_members(l)

    def fetch_and_create_lists(self, user):
        raw = self.fetch_cursored(self.twitter.lists_ownerships,
                                  user_id=user.twitter_id)

        lists = List.query.filter(List.list_id.in_([l['id'] for l in raw]))
        existing_ids = [l.list_id for l in lists]
        for raw_list in [l for l in raw if not l['id'] in existing_ids]:
            l = List(user_id=user.id, list_id=raw_list['id'], raw=raw_list)
            db.session.add(l)
            lists.append(l)

        return lists

    def fetch_members(self, l):
        pass

    @retry_rate_limited
    def fetch_cursored(self, endpoint, **params):
        cursor = -1
        data = []

        while True:
            self.logger.debug("Fetching %s with cursor %d",
                              endpoint.__name__, cursor)

            response = endpoint(**params)
            data.extend(response['lists'])
            cursor = response['next_cursor']

            if not cursor:
                break

        return data
