require 'faraday_middleware'

module Twister
  class User
    attr_reader *%i[ screen_name access_token access_token_secret ]
    attr_reader :connection

    def initialize(**kwargs)
      @screen_name = kwargs.fetch(:screen_name)
      @access_token = kwargs.fetch(:access_token)
      @access_token_secret = kwargs.fetch(:access_token_secret)

      @connection = Faraday.new('https://api.twitter.com/1.1') do |conn|
        conn.request :oauth, consumer_key: ENV['API_KEY'],
                             consumer_secret: ENV['API_SECRET'],
                             token: access_token,
                             token_secret: access_token_secret
        conn.request :json

        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end
    end
  end
end
