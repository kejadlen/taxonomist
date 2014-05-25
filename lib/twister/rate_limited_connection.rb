module Twister
  class RateLimitedConnection
    class RateLimited < StandardError; end

    attr_reader :connection, :rate_limits

    def initialize(connection)
      @connection = connection
      @rate_limits = {}
    end

    def get(endpoint, params={})
      response = connection.get(endpoint, params)

      raise RateLimited if response.status == 429

      response
    rescue RateLimited
      reset = Time.at(response.headers['x-rate-limit-reset'].to_i)
      LOG.warn("Got rate limited; sleeping until #{reset}")
      sleep reset - Time.now + 1
      retry
    end
  end
end
