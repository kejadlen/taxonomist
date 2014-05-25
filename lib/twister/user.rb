module Twister
  class User < Sequel::Model
    many_to_one :friend

    def before_create
      resp = connection.get('account/verify_credentials.json')
      self.friend = Friend.find_or_create(twitter_id: resp.body['id'],
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
end
