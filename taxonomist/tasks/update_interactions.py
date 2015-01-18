from collections import Counter
import logging

from .. import db
from ..models.tweet_mark import TweetMark
from ..models.user import User


class UpdateInteractions:
    def __init__(self, twitter):
        self.twitter = twitter

        self.logger = logging.getLogger('taxonomist')

    def run(self, type, user_id):
        user = User.query.get(user_id)

        tweet_mark = next((tm for tm in user.tweet_marks
                           if tm.type == type.__name__),
                          TweetMark(user_id=user.id, type=type.__name__))
        interactions = {interaction.interactee_id: interaction
                        for interaction in user.interactions
                        if isinstance(interaction, type)}

        data = self.fetch(type, user, since_id=tweet_mark.tweet_id)

        counts = Counter([id
                          for datum in data
                          for id in type.interactee_ids(datum)])
        for id, count in counts.iteritems():
            interaction = interactions.get(id)
            if not interaction:
                interactions[id] = interaction = type(user_id=user.id,
                                                      interactee_id=id,
                                                      count=0)
            interaction.count += count

        if data:
            tweet_mark.tweet_id = data[0]['id']

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
