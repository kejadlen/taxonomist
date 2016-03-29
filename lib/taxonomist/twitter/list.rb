module Taxonomist
  module Twitter
    class List
      def initialize(twitter, id)
        @twitter, @id = twitter, id
      end

      def update!(ids)
        current_ids = twitter.lists_members(id)

        twitter.lists_members_destroy_all(list_id: id, user_id: current_ids - ids)
        twitter.lists_members_create_all(list_id: id, user_id: ids - current_ids)
      end

      private

      attr_reader *%i[ twitter id ]
    end
  end
end
