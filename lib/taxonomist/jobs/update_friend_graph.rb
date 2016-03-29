require_relative "job"

module Taxonomist
  module Jobs
    class UpdateFriendGraph < Job
      def run_rate_limited(user_ids)
        until user_ids.empty?
          id = user_ids.first

          friend_ids = twitter.friends_ids(user_id: id)
          Models::User[twitter_id: id].update(friend_ids: Sequel.pg_array(friend_ids, :bigint))

          user_ids.shift
        end
      end
    end
  end
end
