require_relative "job"

module Taxonomist
  module Jobs
    class HydrateUsers < Job
      USERS_PER_REQUEST = 100

      def run(user_id, user_ids)
        super

        batches = user_ids.each_slice(USERS_PER_REQUEST).to_a
        until batches.empty?
          ids = batches.shift
          friends = self.twitter.users_lookup(user_ids: ids)
                                .each.with_object({}) do |friend, hash|
                                  hash[friend["id"]] = friend
                                end
          ids.each do |id|
            Models::User[twitter_id: id].update(raw: Sequel.pg_json(friends[id]))
          end
        end

        destroy
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id, user_ids, run_at: e.reset_at)
      end
    end
  end
end
