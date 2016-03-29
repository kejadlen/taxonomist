require_relative 'job'

module Taxonomist
  module Jobs
    class HydrateUsers < Job
      USERS_PER_REQUEST = 100

      def run_rate_limited(user_ids)
        batches = user_ids.each_slice(USERS_PER_REQUEST).to_a
        until batches.empty?
          ids = batches.first

          friends = Hash[
            twitter.users_lookup(user_ids: ids).map { |u| [u['id'], u] }
          ]
          ids.each do |id|
            Models::User[twitter_id: id].update(raw: Sequel.pg_json(friends[id]))
          end

          batches.shift
        end
      end
    end
  end
end
