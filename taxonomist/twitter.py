from datetime import datetime
from time import sleep
import logging

from requests_oauthlib import OAuth1Session
import requests


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

    def direct_messages_sent(self, since_id=None, max_id=None):
        params = {'since_id': since_id,
                  'max_id': max_id,
                  'count': 200,
                  'include_entities': 'false'}
        response = self.http(self.oauth.get,
                             '/1.1/direct_messages/sent.json',
                             params=params)
        return response.json()

    def favorites_list(self, user_id, since_id=None, max_id=None):
        params = {'user_id': user_id,
                  'since_id': since_id,
                  'max_id': max_id,
                  'count': 200,
                  'include_entities': 'false'}
        response = self.http(self.oauth.get,
                             '/1.1/favorites/list.json',
                             params=params)
        return response.json()

    def friends_ids(self, user_id):
        """Retrieve the first 5000 friend IDs for the given user."""
        params = {'user_id': user_id}
        response = self.http(self.oauth.get,
                             '/1.1/friends/ids.json',
                             params=params)
        return response.json().get('ids')

    def lists_ownerships(self, user_id, cursor=None):
        params = {'user_id': user_id, 'count': 1000, 'cursor': cursor}
        response = self.http(self.oauth.get,
                             '/1.1/lists/ownerships.json',
                             params=params)
        return response.json()

    def users_lookup(self, user_ids):
        params = {'user_id': ','.join([str(id) for id in user_ids])}
        response = self.http(self.oauth.post,
                             '/1.1/users/lookup.json',
                             data=params)
        return response.json()

    def statuses_user_timeline(self, user_id, since_id=None, max_id=None):
        # Sadly, there's no good way of checking the retweet chain, so
        # we can just ignore RTs for now.
        params = {'user_id': user_id,
                  'since_id': since_id,
                  'max_id': max_id,
                  'count': 200,
                  'trim_user': 'true',
                  'include_rts': 'false'}
        response = self.http(self.oauth.get,
                             '/1.1/statuses/user_timeline.json',
                             params=params)
        return response.json()

    def http(self, func, endpoint, **kwargs):
        response = func(self.url_for(endpoint), **kwargs)
        if response.status_code == requests.codes.too_many_requests:
            raise RateLimitError(response)
        response.raise_for_status()
        return response


def retry_rate_limited(f):
    def retry(*args, **kwargs):
        logger = logging.getLogger('taxonomist')
        while True:
            result = None
            try:
                result = f(*args, **kwargs)
            except RateLimitError as exc:
                delta = exc.rate_limit_reset - datetime.now()
                countdown = delta.total_seconds() + 1
                fmt = "Rate limited trying to hit %s, sleeping for %s seconds"
                logger.warn(fmt, exc.response.url, countdown)
                sleep(countdown)
            return result
    return retry


class RateLimitError(Exception):
    def __init__(self, response):
        self.response = response

    def __str__(self):
        return repr(self.response)

    @property
    def rate_limit_reset(self):
        reset = self.response.headers['x-rate-limit-reset']
        return datetime.fromtimestamp(int(reset))
