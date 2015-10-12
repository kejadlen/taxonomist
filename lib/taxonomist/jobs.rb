require "que"

require_relative "db"
require_relative "twitter"

module Taxonomist
  Que.connection = DB

  module Jobs
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

    class UpdateUser < Job
      def run(user_id)
        super

        user_info = self.twitter.users_show(user_id: user.twitter_id)
        friend_ids = self.twitter.friends_ids(user_id: user.twitter_id)

        DB.transaction do
          self.user.update(raw: user_info,
                           friend_ids: Sequel.pg_array(friend_ids))
          Jobs::HydrateFriends.enqueue(user_id, friend_ids)
          Jobs::UpdateFriendGraph.enqueue(user_id)
          destroy
        end
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id: user_id, run_at: e.reset_at)
      end
    end

    class HydrateFriends < Job
      def run(user_id, friend_ids)
        super

        friend_ids.each_slice(self.users_per_request) do |ids|
          friends = self.twitter.users_lookup(user_ids: ids)
                                .each.with_object({}) do |friend, hash|
                                  hash[friend["id"]] = friend
                                end

          existing_ids = Models::User.where(twitter_id: friends.keys)
                                     .select_map(:twitter_id)
          existing_ids.each do |id|
            Models::User.where(twitter_id: id)
                        .update(raw: Sequel.pg_json(friends[id]))
          end

          nonexistent_friends = friends.reject {|id,_| existing_ids.include?(id) }
          nonexistent_friends.each do |id, friend|
            Models::User.create(twitter_id: id, raw: Sequel.pg_json(friend))
          end
        end

        destroy
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id: user_id,
                           friend_ids: friend_ids,
                           run_at: e.reset_at)
      end

      def users_per_request
        100
      end
    end

    class UpdateFriendGraph < Job
      def run(user_id)
        super
      end
    end
  end
end
