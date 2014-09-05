import os

from requests_oauthlib import OAuth1Session

class Twitter:
    @staticmethod
    def request_token():
        twitter = OAuth1Session(os.environ["API_KEY"],
                                os.environ["API_SECRET"],
                                callback_uri="http://127.0.0.1:5000/callback")

        return twitter.fetch_request_token("https://api.twitter.com/oauth/request_token")

    @staticmethod
    def access_token(oauth_token, oauth_token_secret, oauth_verifier):
        twitter = OAuth1Session(os.environ["API_KEY"],
                                os.environ["API_SECRET"],
                                resource_owner_key=oauth_token,
                                resource_owner_secret=oauth_token_secret,
                                verifier=oauth_verifier)

        return twitter.fetch_access_token("https://api.twitter.com/oauth/access_token")
