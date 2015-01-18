import logging

class Task:
    def __init__(self, twitter):
        self.twitter = twitter
        self.logger = logging.getLogger('taxonomist')
