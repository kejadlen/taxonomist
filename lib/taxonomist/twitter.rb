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

      def friends_ids(user_id:)
        resp = client.get("friends/ids.json", user_id: user_id)
        cursored(resp.body["ids"], resp)
      end

      def users_lookup(user_ids:)
        user_ids = user_ids.join(?,)
        client.get("users/lookup.json", user_id: user_ids).body
      end

      def users_show(user_id:)
        client.get("users/show.json", user_id: user_id).body
      end

      private

      def cursored(obj, resp)
        obj.extend(Cursored)
        obj.attributes = resp.body
        obj
      end

      module Cursored
        include Virtus.module

        attribute :next_cursor, Integer
        attribute :previous_cursor, Integer
      end
    end
  end
end
