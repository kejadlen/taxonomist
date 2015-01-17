from collections import Counter
from datetime import datetime, timedelta
from itertools import izip_longest
from threading import Thread
import logging

from .. import db
from ..models import interaction as interaction
from ..models.tweet_mark import TweetMark
from ..models.user import User
from ..twitter import retry_rate_limited


class UpdateUser:
    STALE = timedelta(weeks=1)

    # TODO Add jitter
    @classmethod
    def is_stale(cls, user):
        return user.updated_at is None or \
                datetime.now() - user.updated_at > cls.STALE

    def __init__(self, user):
        self.user = user
        self.twitter = self.user.twitter

        self.graph_fetcher = GraphFetcher(self.twitter)
        self.hydrator = FriendHydrator(self.twitter)
        self.interaction_updater = UpdateInteractions(self.twitter)

    def run(self):
        if self.is_stale(self.user):
            GraphFetcher(self.twitter).run(self.user)
            FriendHydrator(self.twitter).run(self.user)

        self.create_users()

        stale_friends = [friend for friend in self.user.friends
                         if self.is_stale(friend)]

        threads = []
        threads.append(self.async(self.graph_fetcher.run, *stale_friends))
        threads.append(self.async(self.hydrator.run, *stale_friends))
        for i in [interaction.Mention, interaction.Favorite, interaction.DM]:
            threads.append(self.async(self.interaction_updater.run,
                                      i,
                                      self.user))

        for thread in threads:
            thread.join()

    def create_users(self):
        '''Since we need two levels of friendships for analysis, friends of the
        target user need to exist in the DB to store their friend_ids.
        '''
        existing_ids = [friend.twitter_id for friend in self.user.friends]
        new_users = [User(twitter_id=id) for id in self.user.friend_ids
                     if id not in existing_ids]
        db.session.add_all(new_users)
        db.session.commit()

    def async(self, task, *args):
        thread = Thread(target=task, args=args)
        thread.daemon = True
        thread.start()
        return thread


class GraphFetcher:
    def __init__(self, twitter):
        self.twitter = twitter

    def run(self, *users):
        for user in users:
            ids = self.fetch(user.twitter_id)
            user.friend_ids = ids
        db.session.commit()

    @retry_rate_limited
    def fetch(self, id):
        return self.twitter.friends_ids(id)


class FriendHydrator:
    def __init__(self, twitter):
        self.twitter = twitter

    def run(self, *users):
        for chunk in izip_longest(*([iter(users)] *
                                    self.twitter.USERS_LOOKUP_CHUNK_SIZE)):
            lookup = {user.twitter_id: user for user in self.users}
            profiles = self.fetch(lookup.keys())
            for profile in profiles:
                lookup[profile['id']].raw = profile

        db.session.commit()

    @retry_rate_limited
    def fetch(self, ids):
        return self.twitter.users_lookup(ids)


class UpdateInteractions:
    def __init__(self, twitter):
        self.twitter = twitter

        self.logger = logging.getLogger('taxonomist')

    def run(self, type, user):
        tweet_mark = next((tm for tm in user.tweet_marks
                           if tm.type == type.__name__),
                          TweetMark(user_id=user.id, type=type.__name__))
        interactions = {interaction.interactee_id: interaction
                        for interaction in user.interactions
                        if isinstance(interaction, type)}

        data = self.fetch(type, user, since_id=tweet_mark.tweet_id)

        for id, count in Counter([id for datum in data
                                  for id in type.interactee_ids(datum)]
                                ).iteritems():
            interaction = interactions.get(id)
            if not interaction:
                interactions[id] = interaction = type(user_id=user.id,
                                                      interactee_id=id,
                                                      count=0)
            interaction.count += count

        if data:
            tweet_mark.tweet_id = data[0]['id']
            db.session.add(tweet_mark)

        db.session.add_all(interactions.values())

        try:
            db.session.commit()
        except:
            db.session.rollback()
            raise

    def fetch(self, type, user, since_id=None):
        max_id = None

        data = []
        while True:
            self.logger.debug("since_id: %s, max_id: %s", since_id, max_id)

            response = type.fetch(self.twitter,
                                  user=user,
                                  since_id=since_id,
                                  max_id=max_id)
            if not response:
                break

            data += response
            max_id = response[-1]['id'] - 1

        return data
