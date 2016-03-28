require_relative 'twitter'

module Taxonomist
  class Timeline
    include Enumerable

    attr_reader :twitter, :endpoint, :user_id, :since_id, :max_id
    attr_reader :rate_limited

    def initialize(twitter, endpoint, user_id, since_id=nil, max_id=nil)
      @twitter, @endpoint, @user_id = twitter, endpoint, user_id
      @since_id, @max_id = since_id, max_id
      @data = []
    end

    def each
      loop do
        self._fetch if @data.empty?
        break if @data.empty?

        yield @data.shift
      end
    rescue Twitter::RateLimitedError => error
      @rate_limited = error
    end

    def _fetch
      data = self.twitter.send(self.endpoint,
                               user_id: self.user_id,
                               since_id: self.since_id,
                               max_id: self.max_id)
      return data if data.empty?

      @max_id = data.last['id'] - 1
      @data.concat(data)
    end
  end
end
