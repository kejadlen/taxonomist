require_relative "db"
require_relative "twitter"

module Taxonomist
  module Jobs
    class UpdateUser
      attr_accessor :twitter_adapter

      def initialize
        @twitter_adapter = Twitter::Authed
      end

      def run(user_id:)
        user = Models::User[user_id]
        twitter = twitter_adapter.new(api_key: ENV.fetch('TWITTER_API_KEY'),
                                      api_secret: ENV.fetch('TWITTER_API_SECRET'),
                                      access_token: user.access_token,
                                      access_token_secret: user.access_token_secret)
        ids = twitter.friends_ids(user_id: user.twitter_id)
        user.friend_ids = Sequel.pg_array(ids)
        user.save
      end
    end
  end
end
