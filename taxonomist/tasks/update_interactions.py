from collections import Counter
from threading import Thread

from .. import db
from ..models.interaction import Interaction
from ..models.tweet_mark import TweetMark
from ..twitter import retry_rate_limited
from twitter_task import TwitterTask


class UpdateInteractions:
    def __init__(self, user):
        self.user = user

        twitter = self.user.twitter
        self.timeline = UpdateTimelineInteractions(twitter)
        self.direct_messages = UpdateDirectMessageInteractions(twitter)
        self.favorites = UpdateFavoriteInteractions(twitter)

    def run(self):
        self.timeline.put(self.user)
        self.direct_messages.put(self.user)
        self.favorites.put(self.user)

        self.timeline.join()
        self.direct_messages.join()
        self.favorites.join()


class UpdateTimelineInteractions(TwitterTask):
    ENDPOINT = 'statuses/user_timeline'

    @retry_rate_limited
    def process(self, user):
        interactions = {interaction.interactee_id: interaction
                        for interaction in user.interactions}

        tweet_mark = next((tm for tm in user.tweet_marks
                           if tm.endpoint == self.ENDPOINT),
                          TweetMark(user_id=user.id, endpoint=self.ENDPOINT))
        params = {'since_id': tweet_mark.tweet_id, 'max_id': None}
        max_tweet_id = tweet_mark.tweet_id

        while True:
            self.logger.debug(params)
            tweets = self.twitter.statuses_user_timeline(user.twitter_id,
                                                         **params)

            if not tweets:
                break

            max_tweet_id = max_tweet_id or tweets[0]['id']

            mention_ids = [mention['id']
                           for tweet in tweets
                           for mention in tweet['entities']['user_mentions']]
            for id, count in Counter(mention_ids).iteritems():
                interaction = interactions.get(id)
                if not interaction:
                    interaction = Interaction(user_id=user.id,
                                              interactee_id=id,
                                              count=0)
                    interactions[id] = interaction
                interaction.count += count
            params['max_id'] = tweets[-1]['id'] - 1

        for i in interactions.values():
            self.logger.debug("%d: %d" % (i.interactee_id, i.count))

        tweet_mark.tweet_id = max_tweet_id
        self.logger.debug(tweet_mark.tweet_id)

        db.session.add_all(interactions.values())
        db.session.add(tweet_mark)
        db.session.commit()


class UpdateDirectMessageInteractions(TwitterTask):
    def process(self, user):
        pass


class UpdateFavoriteInteractions(TwitterTask):
    def process(self, user):
        pass
