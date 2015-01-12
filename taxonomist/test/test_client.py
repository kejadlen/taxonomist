import os
import unittest

from ..twitter.client import AuthedClient, Client


@unittest.skipUnless('TEST_CLIENT' in os.environ, '')
class TestClient(unittest.TestCase):
    def setUp(self):
        super(TestClient, self).setUp()

        self.client = Client(os.environ['TWITTER_API_KEY'],
                             os.environ['TWITTER_API_SECRET'])

    def test_request_token(self):
        self.assertTrue('oauth_token' in self.client.request_token())
        self.assertTrue('oauth_token_secret' in self.client.request_token())


@unittest.skipUnless('TEST_CLIENT' in os.environ, '')
class TestAuthedClient(unittest.TestCase):
    def setUp(self):
        super(TestAuthedClient, self).setUp()

        self.client = AuthedClient(os.environ['TWITTER_API_KEY'],
                                   os.environ['TWITTER_API_SECRET'],
                                   os.environ['TWITTER_ACCESS_TOKEN'],
                                   os.environ['TWITTER_ACCESS_TOKEN_SECRET'])

    def test_friends_ids(self):
        self.assertTrue(len(self.client.friends_ids(715073)) > 0)
