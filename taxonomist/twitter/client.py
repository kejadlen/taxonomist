import requests
from requests_oauthlib import OAuth1Session


class RateLimitedError(Exception):
    def __init__(self, response):
        self.response = response

    def __str__(self):
        return repr(self.response)

    @property
    def rate_limit_reset(self):
        reset = self.response.headers['x-rate-limit-reset']
        return datetime.fromtimestamp(int(reset))


class Client:
    """Adapter for hitting the Twitter API."""
    BASE_URL = 'https://api.twitter.com'
    USERS_LOOKUP_CHUNK_SIZE = 100

    def __init__(self, api_key, api_secret):
        self.api_key = api_key
        self.api_secret = api_secret

    def request_token(self):
        oauth = OAuth1Session(self.api_key,
                              self.api_secret,
                              callback_uri='http://127.0.0.1:5000/callback')

        return oauth.fetch_request_token(self.url_for('/oauth/request_token'))

    def access_token(self, oauth_token, oauth_token_secret, oauth_verifier):
        oauth = OAuth1Session(self.api_key,
                              self.api_secret,
                              resource_owner_key=oauth_token,
                              resource_owner_secret=oauth_token_secret,
                              verifier=oauth_verifier)

        return oauth.fetch_access_token(self.url_for('/oauth/access_token'))

    def url_for(self, endpoint):
        return self.BASE_URL + endpoint


class AuthedClient(Client):
    def __init__(self, oauth_token, oauth_token_secret):
        self.oauth = OAuth1Session(api_key,
                                   api_secret,
                                   resource_owner_key=oauth_token,
                                   resource_owner_secret=oauth_token_secret)
