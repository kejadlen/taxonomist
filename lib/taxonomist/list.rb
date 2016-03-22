module Taxonomist
  class List
    attr_reader :id, :twitter
    attr_accessor :remote_ids

    def initialize(id, twitter)
      @id, @twitter = id, twitter
    end

    def pull!
      self.remote_ids = self.twitter.lists_members(self.id)
    end
  end
end
