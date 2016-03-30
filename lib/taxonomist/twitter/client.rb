require 'faraday'
require 'faraday_middleware'

module Taxonomist
  module Twitter
    class RateLimitedError < StandardError
      attr_reader :reset_at

      def initialize(reset_at:)
        @reset_at = reset_at
      end
    end

    class Client
      attr_reader :api_key, :api_secret

      def initialize(api_key:, api_secret:)
        @api_key, @api_secret = api_key, api_secret
      end
    end

    module Client::Cursored
      attr_accessor :next_cursor, :previous_cursor
    end

    class Client::OAuth < Client
      def request_token(callback:)
        resp = conn(callback: callback).post('request_token')
        Faraday::Utils.parse_query(resp.body)
      end

      def access_token(token:, token_secret:, oauth_verifier:)
        oauth = { token: token, token_secret: token_secret }
        resp = conn(oauth).post('access_token', oauth_verifier: oauth_verifier)
        Faraday::Utils.parse_query(resp.body)
      end

      private

      def conn(**oauth)
        return @conn if defined?(@conn)

        oauth = {
          consumer_key: api_key,
          consumer_secret: api_secret
        }.merge(oauth)

        @conn = Faraday.new('https://api.twitter.com/oauth') do |conn|
          conn.request :url_encoded
          conn.request :oauth, oauth

          conn.response :raise_error

          conn.adapter Faraday.default_adapter
        end
      end
    end

    class Client::Authed < Client
      attr_reader :access_token, :access_token_secret

      def initialize(api_key:, api_secret:,
                     access_token:, access_token_secret:)
        super(api_key: api_key, api_secret: api_secret)

        @access_token, @access_token_secret = access_token, access_token_secret

        @conn = Faraday.new('https://api.twitter.com/1.1') do |conn|
          conn.request :oauth, consumer_key: api_key,
                               consumer_secret: api_secret,
                               token: access_token,
                               token_secret: access_token_secret
          conn.request :json
          conn.request :url_encoded

          conn.response :raise_error
          conn.response :json, :content_type => /\bjson$/

          conn.adapter Faraday.default_adapter
        end
      end

      # This takes a user_id that's not actually used to adhere to the
      # interface expected by the Timeline.
      def direct_messages_sent(user_id: nil, since_id: nil, max_id: nil)
        params = { count: 200, include_entities: false }
        params[:since_id] = since_id if since_id
        params[:max_id] = max_id if max_id
        resp = get('direct_messages/sent.json', params)
        resp.body
      end

      def favorites_list(user_id:, since_id: nil, max_id: nil)
        params = { user_id: user_id, count: 200, include_entities: false }
        params[:since_id] = since_id if since_id
        params[:max_id] = max_id if max_id
        resp = get('favorites/list.json', params)
        resp.body
      end

      def friends_ids(user_id:)
        resp = get('friends/ids.json', user_id: user_id)
        cursored(resp.body['ids'], resp)
      end

      def lists_create(name:, mode: nil, description: nil)
        params = { name: name }
        params[:mode] = mode if mode
        params[:description] = description if description
        conn.post('lists/create.json', params) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        end
      end

      def lists_members(list_id:)
        resp = get('lists/members.json', list_id: list_id, count: 5_000)
        cursored(resp.body['users'], resp)
      end

      def lists_members_create_all(list_id:, user_ids:)
        params = { list_id: list_id, user_id: user_ids.join(?,) }
        conn.post('lists/members/create_all.json', params) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        end
      end

      def lists_members_destroy_all(list_id:, user_ids:)
        params = { list_id: list_id, user_id: user_ids.join(?,) }
        conn.post('lists/members/destroy_all.json', params) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        end
      end

      def lists_ownerships(user_id:)
        resp = get('lists/ownerships.json', user_id: user_id, count: 1_000)
        cursored(resp.body['lists'], resp)
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
        get('users/lookup.json', user_id: user_ids).body
      end

      def users_show(user_id:)
        get('users/show.json', user_id: user_id).body
      end

      private

      attr_reader :conn

      def get(endpoint, **kwargs)
        conn.get(endpoint, **kwargs)
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
        obj.next_cursor = resp.body['next_cursor']
        obj.previous_cursor = resp.body['previous_cursor']
        obj
      end
    end
  end
end
