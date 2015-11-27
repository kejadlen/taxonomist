require_relative "job"

module Taxonomist
  module Jobs
    class UpdateLists < Job
      def run(user_id, list_ids)
        super

        until list_ids.empty?
          list_id = list_ids.first

          members = self.twitter.lists_members(list_id: list_id)
          members.each do |member|
            user = Models::User.find_or_create(twitter_id: member["id"])
            user.update(raw: member)
          end

          member_ids = members.map {|member| member["id"]}
          Models::List[twitter_id: list_id].update(member_ids: member_ids)

          list_ids.shift
        end

        destroy
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(user_id, list_ids, run_at: e.reset_at)
      end
    end
  end
end
