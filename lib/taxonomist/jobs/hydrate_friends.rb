require_relative "job"

module Taxonomist
  module Jobs
    class HydrateFriends < Job
      USERS_PER_REQUEST = 100

      def run(user_id, friend_ids)
        super

        friend_ids.each_slice(USERS_PER_REQUEST) do |ids|
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
    end
  end
end
