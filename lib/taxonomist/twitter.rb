require "faraday"
require "faraday_middleware"

module Taxonomist
  class Twitter
    class RateLimitedError < StandardError
      attr_reader :reset_at

      def initialize(reset_at:)
        @reset_at = reset_at
      end
    end

    attr_reader *%i[ api_key api_secret conn ]

    def initialize(api_key:, api_secret:)
      @api_key, @api_secret = api_key, api_secret
    end

    class OAuth < Twitter
      def request_token(callback:)
        conn = Faraday.new("https://api.twitter.com/oauth") do |conn|
          conn.request :oauth, consumer_key: api_key,
                               consumer_secret: api_secret,
                               callback: callback

          conn.response :raise_error

          conn.adapter Faraday.default_adapter
        end

        resp = conn.post("request_token")
        Faraday::Utils.parse_query(resp.body)
      end

      def access_token(token:, token_secret:, oauth_verifier:)
        conn = Faraday.new("https://api.twitter.com/oauth") do |conn|
          conn.request :url_encoded
          conn.request :oauth, consumer_key: api_key,
                               consumer_secret: api_secret,
                               token: token,
                               token_secret: token_secret

          conn.response :raise_error

          conn.adapter Faraday.default_adapter
        end

        resp = conn.post("access_token", oauth_verifier: oauth_verifier)
        Faraday::Utils.parse_query(resp.body)
      end
    end

    class Authed < Twitter
      attr_reader *%i[ access_token access_token_secret ]

      def initialize(api_key:, api_secret:,
                     access_token:, access_token_secret:)
        super(api_key: api_key, api_secret: api_secret)

        @access_token, @access_token_secret = access_token, access_token_secret

        @conn = Faraday.new("https://api.twitter.com/1.1") do |conn|
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

      def lists_members(list_id:)
        resp = get("lists/members.json", list_id: list_id, count: 5_000)
        cursored(resp.body["users"], resp)
      end

      def lists_ownerships(user_id:)
        resp = get("lists/ownerships.json", user_id: user_id, count: 1_000)
        cursored(resp.body["lists"], resp)
      end

      def statuses_user_timeline(user_id:, since_id: nil, max_id: nil)
        params = { user_id: user_id, count: 200, trim_user: true }
        params[:since_id] = since_id if since_id
        params[:max_id] = max_id if max_id
        resp = get('statuses/user_timeline.json', params)
        resp.body
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
        self.conn.get(endpoint, **kwargs)
      rescue Faraday::ClientError => e
        response = e.response
        if response[:status] == 429
          reset_at = Time.at(response[:headers]['x-rate-limit-reset'].to_i)
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
        attr_accessor *%i[ next_cursor previous_cursor ]
      end
    end
  end
end
