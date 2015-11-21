require_relative "job"

module Taxonomist
  module Jobs
    class UpdateFriendGraph < Job
      def run(user_id, user_ids)
        super

        until user_ids.empty?
          id = user_ids.first

          friend_ids = self.twitter.friends_ids(user_id: id)
          Models::User[twitter_id: id].update(friend_ids: Sequel.pg_array(friend_ids, :bigint))

          user_ids.shift
        end

        destroy
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id, user_ids, run_at: e.reset_at)
      end
    end
  end
end
