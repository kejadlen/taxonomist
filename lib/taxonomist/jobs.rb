require "que"

require_relative "db"
require_relative "twitter"

module Taxonomist
  Que.connection = DB

  module Jobs
    class Job < Que::Job
      attr_accessor :twitter, :user

      def run(user_id, *args)
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
        super

        info = self.twitter.users_show(user_id: user.twitter_id)
        ids = self.twitter.friends_ids(user_id: user.twitter_id)

        DB.transaction do
          self.user.update(raw: info, friend_ids: Sequel.pg_array(ids))
          Jobs::HydrateFriends.enqueue(user_id)
          Jobs::UpdateFriendGraph.enqueue(user_id)
          destroy
        end
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id: user_id, run_at: e.reset_at)
      end
    end

    class HydrateFriends < Job
      def run(user_id)
        super

        friends = self.twitter.users_lookup(user_ids: self.user.friend_ids)

        DB.transaction do
          friends.each do |friend|
            Models::User.create(twitter_id: friend["id"],
                                raw: Sequel.pg_json(friend))
          end
          destroy
        end
      end
    end

    class UpdateFriendGraph < Job
      def run(user_id)
        super
      end
    end
  end
end
