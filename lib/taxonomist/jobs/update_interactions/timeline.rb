require_relative '../update_interactions'

module Taxonomist
  module Jobs
    class UpdateInteractions::Timeline < UpdateInteractions
      def endpoint
        :statuses_user_timeline
      end
    end
  end
end
