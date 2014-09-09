from datetime import datetime
import os

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


class Twitter:
    BASE_URL = 'https://api.twitter.com'
    USERS_LOOKUP_CHUNK_SIZE = 100

    @classmethod
    def url_for(cls, endpoint):
        return cls.BASE_URL + endpoint

    @classmethod
    def request_token(cls):
        oauth = OAuth1Session(os.environ['API_KEY'],
                              os.environ['API_SECRET'],
                              callback_uri='http://127.0.0.1:5000/callback')

        return oauth.fetch_request_token(cls.url_for('/oauth/request_token'))

    @classmethod
    def access_token(cls, oauth_token, oauth_token_secret, oauth_verifier):
        oauth = OAuth1Session(os.environ['API_KEY'],
                              os.environ['API_SECRET'],
                              resource_owner_key=oauth_token,
                              resource_owner_secret=oauth_token_secret,
                              verifier=oauth_verifier)

        return oauth.fetch_access_token(cls.url_for('/oauth/access_token'))

    def __init__(self, oauth_token, oauth_token_secret):
        self.oauth = OAuth1Session(os.environ['API_KEY'],
                                   os.environ['API_SECRET'],
                                   resource_owner_key=oauth_token,
                                   resource_owner_secret=oauth_token_secret)

    def friends_ids(self, user_id):
        payload = {'user_id': user_id}
        response = self.http(self.oauth.get,
                             '/1.1/friends/ids.json',
                             params=payload)
        # response = self.oauth.get(self.url_for('/1.1/friends/ids.json'),
        #                           params=payload)
        return (response.json().get('ids'), response)

    def users_lookup(self, user_ids):
        payload = {'user_id': ','.join([str(id) for id in user_ids])}
        response = self.http(self.oauth.post,
                             '/1.1/users/lookup.json',
                             data=payload)
        # response = self.oauth.post(self.url_for('/1.1/users/lookup.json'),
        #                            data=payload)
        return (response.json(), response)

    def http(self, func, endpoint, **kwargs):
        response = func(self.url_for(endpoint), **kwargs)
        if response.status_code == requests.codes.too_many_requests:
            raise RateLimitedError(response)
        response.raise_for_status()
        return response
