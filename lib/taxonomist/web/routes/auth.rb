module Taxonomist
  module Web
    App.route('auth') do |r|
      r.get 'sign_in' do
        twitter_oauth = Twitter::Client::OAuth.new(
          api_key: ENV['TWITTER_API_KEY'],
          api_secret: ENV['TWITTER_API_SECRET'],
        )

        callback = "http://#{r.host_with_port}/auth/callback"
        request_token = twitter_oauth.request_token(callback: callback)

        r.session[:token] = request_token['oauth_token']
        r.session[:token_secret] = request_token['oauth_token_secret']

        url = "https://api.twitter.com/oauth/authorize?oauth_token=#{r.session[:token]}"
        r.redirect url
      end

      # TODO Verify oauth_token is the same as before?
      r.get 'callback' do
        token = r.session.delete(:token)
        token_secret = r.session.delete(:token_secret)

        twitter_oauth = Twitter::Client::OAuth.new(
          api_key: ENV['TWITTER_API_KEY'],
          api_secret: ENV['TWITTER_API_SECRET'],
        )
        access_token = twitter_oauth.access_token(
          token: token,
          token_secret: token_secret,
          oauth_verifier: r.params['oauth_verifier'],
        )

        oauth_token = access_token['oauth_token']
        oauth_token_secret = access_token['oauth_token_secret']
        user_id = access_token['user_id']
        screen_name = access_token['screen_name']

        user = Models::User.find_or_create(twitter_id: user_id)
        user.update(access_token: oauth_token,
                    access_token_secret: oauth_token_secret)

        r.session[:twitter_id] = user_id

        r.redirect '/'
      end

      r.get 'sign_out' do
        r.session.delete(:twitter_id)
        r.redirect '/'
      end
    end
  end
end
