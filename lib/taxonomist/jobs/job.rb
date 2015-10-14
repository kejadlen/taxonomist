require "que"

require_relative "../db"
require_relative "../twitter"

module Taxonomist
  module Jobs
    Que.connection = DB

    class Job < Que::Job
      TWITTER_ADAPTER = Twitter::Authed

      attr_accessor :twitter, :user

      def run(user_id, *args)
        self.user = Models::User[user_id]

        api_key = ENV.fetch('TWITTER_API_KEY')
        api_secret = ENV.fetch('TWITTER_API_SECRET')
        access_token = self.user.access_token
        access_token_secret = self.user.access_token_secret
        self.twitter = TWITTER_ADAPTER.new(api_key: api_key,
                                           api_secret: api_secret,
                                           access_token: access_token,
                                           access_token_secret: access_token_secret)
      end
    end
  end
end
