require "faraday"
require "faraday_middleware"
require "virtus"

module Taxonomist
  class Twitter
    include Virtus.model

    attribute :api_key, String
    attribute :api_secret, String

    attr_reader :client

    class Authed < Twitter
      attribute :access_token, String
      attribute :access_token_secret, String

      def initialize(*)
        super

        @client = Faraday.new("https://api.twitter.com/1.1") do |conn|
          conn.request :oauth, consumer_key: api_key,
                               consumer_secret: api_secret,
                               token: access_token,
                               token_secret: access_token_secret
          conn.request :json

          conn.response :json, :content_type => /\bjson$/

          conn.adapter Faraday.default_adapter
        end
      end

      def users_show(user_id:)
        client.get("users/show.json", user_id: user_id).body
      end
    end
  end
end
