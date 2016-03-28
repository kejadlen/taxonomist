require_relative "job"

module Taxonomist
  module Jobs
    class UpdateLists < Job
      def run_rate_limited(list_ids)
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
      end
    end
  end
end
