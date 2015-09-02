require "que"

require_relative "db"
require_relative "twitter"

module Taxonomist
  Que.connection = DB

  module Jobs
    class Job < Que::Job
      attr_accessor :twitter, :user

      def setup!(user_id)
        self.user = Models::User[user_id]

        api_key = ENV.fetch('TWITTER_API_KEY')
        api_secret = ENV.fetch('TWITTER_API_SECRET')
        access_token = self.user.access_token
        access_token_secret = self.user.access_token_secret
        self.twitter = self.twitter_adapter.new(api_key: api_key,
                                                api_secret: api_secret,
                                                access_token: access_token,
                                                access_token_secret: access_token_secret)
      end

      def twitter_adapter
        Twitter::Authed
      end
    end

    class UpdateUser < Job
      def run(user_id)
        setup!(user_id)

        ids = self.twitter.friends_ids(user_id: user.twitter_id)

        DB.transaction do
          self.user.update(friend_ids: Sequel.pg_array(ids))
          destroy
        end
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id: user_id, run_at: e.reset_at)
      end
    end

    class HydrateUsers < Job
      def run(user_id, user_ids)
        setup!(user_id)

        friends = self.twitter.users_lookup(user_ids: user_ids)

        DB.transaction do
          friends.each do |friend|
            Models::User.create(twitter_id: friend["id"],
                                raw: Sequel.pg_json(friend))
          end
          destroy
        end
      end
    end
  end
end
