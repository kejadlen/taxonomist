require 'logger'

require 'faraday_middleware'

require_relative 'twister/db'

module Twister
  API_KEY = ENV.fetch('API_KEY')
  API_SECRET = ENV.fetch('API_SECRET')

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

    # We only fetch the first page of friend ids since I'm lazy
    def fetch_friends
      # TODO handle rate limiting here
      resp = user.connection.get('friends/ids.json', user_id: twitter_id)
      self.friend_ids = resp.body['ids'].map(&:to_s)
      save
    end
  end
end
