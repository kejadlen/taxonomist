module Taxonomist
  class ListUpdate
    attr_accessor :ids

    def initialize(twitter, id, ids: [])
      @twitter, @id, @ids = twitter, id, ids
    end

    def diff
      { insertions: insertions, deletions: deletions }
    end

    def commit!
      twitter.lists_members_destroy_all(list_id: id, user_ids: deletions)
      twitter.lists_members_create_all(list_id: id, user_ids: insertions)
    end

    private

    attr_reader *%i[ twitter id ]

    def insertions
      ids - remote_ids
    end

    def deletions
      remote_ids - ids
    end

    def remote_ids
      return @remote_ids if defined?(@remote_ids)

      @remote_ids = twitter.lists_members(list_id: id).map {|m| m['id'] }
    end
  end
end
