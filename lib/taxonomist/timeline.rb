module Taxonomist
  class Timeline
    include Enumerable

    attr_reader :twitter, :endpoint, :user_id, :since_id
    attr_accessor :max_id
    attr_reader :data

    def initialize(twitter, endpoint, user_id, since_id=nil, max_id=nil)
      @twitter, @endpoint, @user_id = twitter, endpoint, user_id
      @since_id, @max_id = since_id, max_id
      @data = []
    end

    def each
      loop do
        self._fetch if self.data.empty?
        break if self.data.empty?

        yield self.data.shift
      end
    end

    def _fetch
      data = self.twitter.send(self.endpoint,
                               user_id: self.user_id,
                               since_id: self.since_id,
                               max_id: self.max_id)
      return data if data.empty?

      self.max_id = data.last['id'] - 1
      self.data.concat(data)
    end
  end
end
