require_relative "job"

require_relative "hydrate_users"
require_relative "update_friend_graph"
require_relative "update_lists"

module Taxonomist
  module Jobs
    class UpdateUser < Job
      def run_rate_limited
        user_info = self.twitter.users_show(user_id: self.user.twitter_id)
        friend_ids = self.twitter.friends_ids(user_id: self.user.twitter_id)
        lists = self.twitter.lists_ownerships(user_id: self.user.twitter_id)
        list_ids = lists.map {|list| list["id"] }

        self.update_user(user_info, friend_ids, list_ids)
        self.update_lists(lists)
        self.create_friends(friend_ids)

        self.enqueue_child_jobs
      end

      def update_user(user_info, friend_ids, list_ids)
        self.user.update(
          raw: Sequel.pg_json(user_info),
          friend_ids: Sequel.pg_array(friend_ids),
          list_ids: Sequel.pg_array(list_ids),
        )
      end

      def update_lists(lists)
        lists.each do |raw|
          list = Models::List.find_or_create(twitter_id: raw["id"])
          list.update(raw: raw)
        end
      end

      def create_friends(friend_ids)
        existing_ids = Models::User.where(twitter_id: friend_ids).select_map(:twitter_id)
        (friend_ids - existing_ids).each do |id|
          Models::User.create(twitter_id: id)
        end
      end

      def enqueue_child_jobs
        Jobs::UpdateLists.enqueue(self.user.id, self.user.list_ids)
        Jobs::HydrateUsers.enqueue(self.user.id, self.user.friend_ids)
        Jobs::UpdateFriendGraph.enqueue(self.user.id, self.user.friend_ids)
      end
    end
  end
end
