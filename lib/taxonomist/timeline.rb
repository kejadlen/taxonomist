require_relative 'twitter'

module Taxonomist
  class Timeline
    include Enumerable

    attr_reader :twitter, :endpoint, :user_id, :since_id, :max_id
    attr_reader :statuses, :rate_limited

    def initialize(twitter, endpoint, user_id, since_id=nil, max_id=nil)
      @twitter, @endpoint, @user_id = twitter, endpoint, user_id
      @since_id, @max_id = since_id, max_id
    end

    def fetch!
      @statuses = []
      loop do
        data = twitter.send(endpoint,
                            user_id: user_id,
                            since_id: since_id,
                            max_id: max_id)
        return if data.empty?

        @max_id = data.last['id'] - 1
        statuses.concat(data)
      end
    rescue Twitter::RateLimitedError => error
      @rate_limited = error
    end
  end
end
