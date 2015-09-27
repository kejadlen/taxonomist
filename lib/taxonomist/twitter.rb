require "faraday"
require "faraday_middleware"
require "virtus"

module Taxonomist
  class Twitter
    class RateLimitedError < StandardError
      include Virtus.model

      attribute :reset_at, DateTime
    end

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

          conn.response :raise_error
          conn.response :json, :content_type => /\bjson$/

          conn.adapter Faraday.default_adapter
        end
      end

      def friends_ids(user_id:)
        resp = get("friends/ids.json", user_id: user_id)
        cursored(resp.body["ids"], resp)
      end

      def users_lookup(user_ids:)
        user_ids = user_ids.join(?,)
        get("users/lookup.json", user_id: user_ids).body
      end

      def users_show(user_id:)
        get("users/show.json", user_id: user_id).body
      end

      private

      def get(endpoint, **kwargs)
        client.get(endpoint, **kwargs)
      rescue Faraday::ClientError => e
        response = e.response
        if response.status == 429
          reset_at = response.headers['x-rate-limit-reset'].to_i
          raise RateLimitedError.new(reset_at: reset_at)
        end
        raise
      end

      def cursored(obj, resp)
        obj.extend(Cursored)
        obj.next_cursor = resp.body["next_cursor"]
        obj.previous_cursor = resp.body["previous_cursor"]
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
