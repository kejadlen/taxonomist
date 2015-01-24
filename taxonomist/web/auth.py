from flask import redirect, request, session, url_for
import os


@app.route('/signin')
def signin():
    client = Client(os.environ["TWITTER_API_KEY"],
                    os.environ["TWITTER_API_SECRET"])
    request_token = client.request_token()

    session['oauth_token'] = request_token.get('oauth_token')
    session['oauth_token_secret'] = request_token.get('oauth_token_secret')

    url = 'https://api.twitter.com/oauth/authorize?oauth_token=%s'
    return redirect(url % session['oauth_token'])


@app.route('/callback')
def callback():
    oauth_token = session.pop('oauth_token')
    oauth_token_secret = session.pop('oauth_token_secret')
    oauth_verifier = request.args.get('oauth_verifier')

    client = Client(os.environ["TWITTER_API_KEY"],
                    os.environ["TWITTER_API_SECRET"])
    access_token = client.access_token(oauth_token,
                                       oauth_token_secret,
                                       oauth_verifier)

    oauth_token = access_token.get('oauth_token')
    oauth_token_secret = access_token.get('oauth_token_secret')
    user_id = access_token.get('user_id')
    screen_name = access_token.get('screen_name')

    user = User.query.filter_by(twitter_id=user_id).scalar()
    if not user:
        user = User(user_id, friend_ids=[])
        db.session.add(user)
    user.oauth_token = oauth_token
    user.oauth_token_secret = oauth_token_secret
    db.session.commit()
    session['user_id'] = user.id

    return redirect(url_for('index'))
