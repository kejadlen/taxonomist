require "dotenv"
Dotenv.load

require "roda"
require "tilt/erb"

require_relative "db"
require_relative "twitter"

module Taxonomist
  class Web < Roda
    use Rack::Session::Cookie, secret: ENV["RODA_SECRET"]

    opts[:root] = File.expand_path("../web", __FILE__)

    plugin :render, views: "views"

    route do |r|
      r.root do
        if r.session.has_key?(:user_id)
          r.redirect "filter"
        else
          view "index"
        end
      end

      r.get "filter" do
        "Hello world!"
      end

      r.get "sign_out" do
        r.session.delete(:user_id)
        r.redirect "/"
      end

      r.on "oauth" do
        r.get "sign_in" do
          twitter_oauth = Twitter::OAuth.new(api_key: ENV["TWITTER_API_KEY"],
                                             api_secret: ENV["TWITTER_API_SECRET"])

          callback = "http://#{r.host_with_port}/oauth/callback"
          request_token = twitter_oauth.request_token(callback: callback)

          r.session[:token] = request_token["oauth_token"]
          r.session[:token_secret] = request_token["oauth_token_secret"]

          url = "https://api.twitter.com/oauth/authorize?oauth_token=#{r.session[:token]}"
          r.redirect url
        end

        # TODO Verify oauth_token is the same as before?
        r.get "callback" do
          token = r.session.delete(:token)
          token_secret = r.session.delete(:token_secret)

          twitter_oauth = Twitter::OAuth.new(api_key: ENV["TWITTER_API_KEY"],
                                             api_secret: ENV["TWITTER_API_SECRET"])
          access_token = twitter_oauth.access_token(token: token, token_secret: token_secret,
                                                    oauth_verifier: r.params["oauth_verifier"])

          oauth_token = access_token["oauth_token"]
          oauth_token_secret = access_token["oauth_token_secret"]
          user_id = access_token["user_id"]
          screen_name = access_token["screen_name"]

          user = Models::User.find_or_create(twitter_id: user_id)
          user.update(access_token: oauth_token, access_token_secret: oauth_token_secret)

          r.session[:user_id] = user_id

          r.redirect "/"
        end
      end
    end
  end
end
