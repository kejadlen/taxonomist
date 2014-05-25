require 'logger'

require 'faraday_middleware'

require_relative 'twister/db'

require_relative 'twister/friend'
require_relative 'twister/initial_fetcher'
require_relative 'twister/rate_limited_connection'
require_relative 'twister/user'

module Twister
  API_KEY = ENV.fetch('API_KEY')
  API_SECRET = ENV.fetch('API_SECRET')
  LOG = Logger.new(STDOUT)
  # LOG.level = Logger::DEBUG
end
