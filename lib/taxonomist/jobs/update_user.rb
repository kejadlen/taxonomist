require_relative 'job'

require_relative 'hydrate_users'
require_relative 'refresh_friend_graph'
require_relative 'update_lists'

module Taxonomist
  module Jobs
    class UpdateUser < Job
      private

      def run_rate_limited
        user_info = twitter.users_show(user_id: user.twitter_id)
        friend_ids = twitter.friends_ids(user_id: user.twitter_id)
        lists = twitter.lists_ownerships(user_id: user.twitter_id)
        list_ids = lists.map {|list| list['id'] }

        update_user(user_info, friend_ids, list_ids)
        update_lists(lists)
        create_friends(friend_ids)

        enqueue_child_jobs
      end

      def update_user(user_info, friend_ids, list_ids)
        user.update(
          raw: Sequel.pg_json(user_info),
          friend_ids: Sequel.pg_array(friend_ids),
          list_ids: Sequel.pg_array(list_ids),
        )
      end

      def update_lists(lists)
        lists.each do |raw|
          list = Models::List.find_or_create(twitter_id: raw['id'])
          list.update(raw: raw)
        end
      end

      def create_friends(friend_ids)
        existing_ids = Models::User.where(twitter_id: friend_ids)
                                   .select_map(:twitter_id)
        (friend_ids - existing_ids).each do |id|
          Models::User.create(twitter_id: id)
        end
      end

      def enqueue_child_jobs
        # Jobs::UpdateLists.enqueue(user.id, user.list_ids)
        Jobs::HydrateUsers.enqueue(user.id, user.friend_ids)
        Jobs::RefreshFriendGraph.enqueue(user.id, user.friend_ids)
      end
    end
  end
end
