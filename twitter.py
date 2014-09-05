import os

from requests_oauthlib import OAuth1Session

class Twitter:
    BASE_URL = "https://api.twitter.com"

    @classmethod
    def request_token(cls):
        twitter = OAuth1Session(os.environ["API_KEY"],
                                os.environ["API_SECRET"],
                                callback_uri="http://127.0.0.1:5000/callback")

        return twitter.fetch_request_token(cls.BASE_URL + "/oauth/request_token")

    @classmethod
    def access_token(cls, oauth_token, oauth_token_secret, oauth_verifier):
        twitter = OAuth1Session(os.environ["API_KEY"],
                                os.environ["API_SECRET"],
                                resource_owner_key=oauth_token,
                                resource_owner_secret=oauth_token_secret,
                                verifier=oauth_verifier)

        return twitter.fetch_access_token(cls.BASE_URL + "/oauth/access_token")

    def __init__(self, oauth_token, oauth_token_secret):
        self.oauth = OAuth1Session(os.environ["API_KEY"],
                                   os.environ["API_SECRET"],
                                   resource_owner_key=oauth_token,
                                   resource_owner_secret=oauth_token_secret)

    def friends_ids(self, user_id):
        params = {"user_id":user_id}
        response = self.oauth.get(self.BASE_URL + "/1.1/friends/ids.json", params=params)
        return (response.json().get("ids"), response)
