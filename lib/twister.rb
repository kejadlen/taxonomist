require 'logger'

require 'faraday_middleware'

require_relative 'twister/db'

module Twister
  API_KEY = ENV.fetch('API_KEY')
  API_SECRET = ENV.fetch('API_SECRET')
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::DEBUG

  class User < Sequel::Model
    many_to_one :friend

    def before_create
      resp = connection.get('account/verify_credentials.json')
      self.friend = Friend.find_or_create(twitter_id: resp.body['id'],
                                          screen_name: resp.body['screen_name'])
    end

    def connection
      return @connection if defined?(@connection)

      connection = Faraday.new('https://api.twitter.com/1.1') do |conn|
        conn.request :oauth, consumer_key: API_KEY,
                             consumer_secret: API_SECRET,
                             token: access_token,
                             token_secret: access_token_secret
        conn.request :json

        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end

      @connection = RateLimitedConnection.new(connection)
    end
  end

  class Friend < Sequel::Model
    one_to_one :user

    def friends
      self.class.where(twitter_id: friend_ids.to_a)
    end

    def fetch_friends(connection)
      LOG.debug("Fetching friends for #{twitter_id}")

      response = connection.get('friends/ids.json', user_id: twitter_id)
      update(friend_ids: response.body['ids'].map(&:to_i))
    end

    def hydrate_friends(connection)
      friends.where(screen_name: nil).each_slice(100) do |slice|
        response = connection.get('users/lookup.json',
                                  user_id: slice.map(&:twitter_id).join(','))
        response.body.each do |user|
          Friend.where(twitter_id: user['id'])
                .update(screen_name: user['screen_name'])
        end
      end
    end
  end

  class InitialFetcher
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def run
      user.friend.fetch_friends(user.connection)
      user.friend.hydrate_friends(user.connection)
      user.friend.friends.each do |friend|
        friend.fetch_friends(user.connection)
      end
    end
  end

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
