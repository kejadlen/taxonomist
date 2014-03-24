require 'logger'

require 'faraday_middleware'
require 'sequel'

module Twister
  API_KEY = ENV.fetch('API_KEY')
  API_SECRET = ENV.fetch('API_SECRET')
  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
  DB.loggers << Logger.new(STDOUT)

  class User < Sequel::Model
    many_to_one :friend

    def after_create
      resp = connection.get('account/verify_credentials.json')
      self.friend = Friend.create(twitter_id: resp.body['id_str'],
                                  screen_name: resp.body['screen_name'])
    end

    def connection
      @connection ||= Faraday.new('https://api.twitter.com/1.1') do |conn|
        conn.request :oauth, consumer_key: API_KEY,
                             consumer_secret: API_SECRET,
                             token: access_token,
                             token_secret: access_token_secret
        conn.request :json

        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end
    end
  end

  class Friend < Sequel::Model
    one_to_one :user
  end
end
