require_relative '../update_interactions'

module Taxonomist
  module Jobs
    class UpdateInteractions::Timeline < UpdateInteractions
      def endpoint
        :statuses_user_timeline
      end

      def interactee_ids(status)
        user_mentions = Array(status.dig('entities', 'user_mentions'))
        ids = user_mentions.map {|um| um['id'] }
        ids << status.dig('quoted_status', 'user', 'id')
        ids.compact
      end
    end
  end
end
