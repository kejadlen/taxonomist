require_relative 'job'

require_relative 'hydrate_users'
require_relative 'refresh_friend_graph'

module Taxonomist
  module Jobs
    class RefreshUser < Job
      private

      def run_rate_limited
        user_info = twitter.users_show(user_id: user.twitter_id)
        friend_ids = twitter.friends_ids(user_id: user.twitter_id)

        update_user(user_info, friend_ids)
        create_friends(friend_ids)

        enqueue_child_jobs
      end

      def update_user(user_info, friend_ids)
        user.update(
          raw: Sequel.pg_json(user_info),
          friend_ids: Sequel.pg_array(friend_ids),
        )
      end

      def create_friends(friend_ids)
        existing_ids = Models::User.where(twitter_id: friend_ids)
                                   .select_map(:twitter_id)
        (friend_ids - existing_ids).each do |id|
          Models::User.create(twitter_id: id)
        end
      end

      def enqueue_child_jobs
        Jobs::HydrateUsers.enqueue(user.id, user.friend_ids)
        Jobs::RefreshFriendGraph.enqueue(user.id, user.friend_ids)
      end
    end
  end
end
