from collections import Counter
from threading import Event, Thread
import logging

from .. import db
from ..models import interaction as interaction
from ..models.tweet_mark import TweetMark
from ..twitter import retry_rate_limited
from twitter_task import TwitterTask


class UpdateInteractions:
    def __init__(self, user):
        self.user = user
        self.twitter = user.twitter

        endpoint = self.endpoint.__name__
        self.tweet_mark = next((tm for tm in user.tweet_marks
                                if tm.endpoint == endpoint),
                               TweetMark(user_id=user.id, endpoint=endpoint))

        self.interactions = {interaction.interactee_id: interaction
                             for interaction in user.interactions}

        self.event = Event()
        self.event.clear()

        self.logger = logging.getLogger('taxonomist')

    def start(self):
        self.thread = Thread(target=self.run)
        self.thread.daemon = True
        self.thread.start()

    def run(self):
        data = self.fetch(self.user, since_id=self.tweet_mark.tweet_id)

        counts = Counter([id
                          for datum in data
                          for id in self.interactee_ids(datum)])

        for id, count in counts.iteritems():
            interaction = self.interactions.get(id)
            if not interaction:
                interaction = Interaction(user_id=self.user.id,
                                          interactee_id=id,
                                          count=0)
                self.interactions[id] = interaction
            interaction.count += count

        if data:
            self.tweet_mark.tweet_id = data[0]['id']
            db.session.add(self.tweet_mark)

        db.session.add_all(self.interactions.values())

        try:
            db.session.commit()
        except:
            db.session.rollback()
            raise

        self.event.set()

    def join(self):
        self.event.wait()

    @retry_rate_limited
    def fetch(self, user, since_id=None):
        max_id = None

        tweets = []
        while True:
            self.logger.debug("since_id: %s, max_id: %s", since_id, max_id)
            response = self.endpoint(user.twitter_id,
                                     since_id=since_id,
                                     max_id=max_id)
            if not response:
                break

            tweets += response
            max_id = response[-1]['id'] - 1

        return tweets


class UpdateMentionInteractions(UpdateInteractions):
    @property
    def endpoint(self):
        return self.twitter.statuses_user_timeline

    def interactee_ids(self, tweet):
        return [user['id'] for user in tweet['entities']['user_mentions']]


class UpdateDMInteractions(TwitterTask):
    @property
    def endpoint(self):
        return self.twitter.favorites_list

    def interactee_ids(self, tweet):
        return [tweet['user']['id']]


class UpdateFavoriteInteractions(TwitterTask):
    pass
    # @property
    # def endpoint(self):
    #     return self.twitter.statuses_user_timeline

    # def interactee_ids(self, tweet):
    #     return [user['id'] for user in tweet['entities']['user_mentions']]
