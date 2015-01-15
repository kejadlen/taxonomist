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
        interactions = user.interactions
        tweet_mark = next((tm for tm in user.tweet_marks
                           if tm.endpoint == self.ENDPOINT),
                          TweetMark(endpoint=self.ENDPOINT))

        while True:
            tweets = self.twitter.statuses_user_timeline(user.twitter_id,
                                                         **tweet_mark.params)
            mention_ids = [mention['id']
                           for tweet in tweets
                           for mention in tweet['entities']['user_mentions']]
            for id, count in Counter(mention_ids).iteritems():
                # interaction = next((i for i in interactions
                #                     if i.interactee_id == id),
                #                    None)
                # if interaction is None:
                #     db.Session.add(Interaction(user_id=user.id,
                #                                interactee_id=id,
                #                                count=count))
                # else:
                interaction = next((i for i in interactions
                                    if i.interactee_id == id),
                                   Interaction(user_id=user.id,
                                               interactee_id=id,
                                               count=count))
                interaction.count += count
                import pdb; pdb.set_trace()
                db.Session.add(interaction)
            db.Session.commit()

            return


class UpdateDirectMessageInteractions(TwitterTask):
    def process(self, user):
        pass


class UpdateFavoriteInteractions(TwitterTask):
    def process(self, user):
        pass
