import os
import unittest

from taxonomist.twitter.client import Client


@unittest.skipUnless('TEST_CLIENT' in os.environ, '')
class TestClient(unittest.TestCase):
    def setUp(self):
        super(TestClient, self).setUp()

        self.client = Client(os.environ['TWITTER_API_KEY'],
                             os.environ['TWITTER_API_SECRET'])

    def test_request_token(self):
        self.assertTrue('oauth_token' in self.client.request_token())
        self.assertTrue('oauth_token_secret' in self.client.request_token())
