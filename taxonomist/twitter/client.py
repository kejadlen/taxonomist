from datetime import datetime

import requests
from requests_oauthlib import OAuth1Session


class RateLimitError(Exception):
    def __init__(self, response):
        self.response = response

    def __str__(self):
        return repr(self.response)

    @property
    def rate_limit_reset(self):
        reset = self.response.headers['x-rate-limit-reset']
        return datetime.fromtimestamp(int(reset))


class Client(object):
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
    def __init__(self, api_key, api_secret, oauth_token, oauth_token_secret):
        super(AuthedClient, self).__init__(api_key, api_secret)

        self.oauth = OAuth1Session(api_key,
                                   api_secret,
                                   resource_owner_key=oauth_token,
                                   resource_owner_secret=oauth_token_secret)

    def friends_ids(self, user_id):
            """Retrieve the first 5000 friend IDs for the given user."""
            payload = {'user_id': user_id}
            response = self.http(self.oauth.get,
                                 '/1.1/friends/ids.json',
                                 params=payload)
            return response.json().get('ids')

    def users_lookup(self, user_ids):
        payload = {'user_id': ','.join([str(id) for id in user_ids])}
        response = self.http(self.oauth.post,
                             '/1.1/users/lookup.json',
                             data=payload)
        return response.json()

    def http(self, func, endpoint, **kwargs):
        response = func(self.url_for(endpoint), **kwargs)
        if response.status_code == requests.codes.too_many_requests:
            raise RateLimitError(response)
        response.raise_for_status()
        return response