require_relative "db"
require_relative "twitter"

module Taxonomist
  module Jobs
    class Job
      attr_accessor :twitter, :twitter_adapter, :user

      def initialize
        @twitter_adapter = Twitter::Authed
      end

      def setup!(user_id:)
        self.user = Models::User[user_id]

        api_key = ENV.fetch('TWITTER_API_KEY')
        api_secret = ENV.fetch('TWITTER_API_SECRET')
        access_token = self.user.access_token
        access_token_secret = self.user.access_token_secret
        self.twitter = twitter_adapter.new(api_key: api_key,
                                           api_secret: api_secret,
                                           access_token: access_token,
                                           access_token_secret: access_token_secret)
      end
    end

    class HydrateUsers < Job
      def run(user_id:, user_ids:)
        setup!(user_id: user_id)

        friends = self.twitter.users_lookup(user_ids: user_ids)
        friends.each do |friend|
          Models::User.create(twitter_id: friend["id"],
                              raw: Sequel.pg_json(friend))
        end
      end
    end

    class UpdateUser < Job
      def run(user_id:)
        setup!(user_id: user_id)

        ids = self.twitter.friends_ids(user_id: user.twitter_id)
        self.user.friend_ids = Sequel.pg_array(ids)
        self.user.save
      end
    end
  end
end
