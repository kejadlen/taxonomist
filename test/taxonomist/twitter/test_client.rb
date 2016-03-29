require_relative '../../test_helper'

require 'taxonomist/twitter/client'

class TestTwitterClient < Test
  def self.runnable_methods
    return [] unless ENV.has_key?('TEST_TWITTER')

    super
  end

  def setup
    api_key = ENV.fetch('TWITTER_API_KEY')
    api_secret = ENV.fetch('TWITTER_API_SECRET')
    access_token = ENV.fetch('TWITTER_ACCESS_TOKEN')
    access_token_secret = ENV.fetch('TWITTER_ACCESS_TOKEN_SECRET')

    @twitter = Twitter::Client::Authed.new(api_key: api_key,
                                           api_secret: api_secret,
                                           access_token: access_token,
                                           access_token_secret: access_token_secret)
  end

  def test_authed
    user = @twitter.users_show(user_id: 2244994945)
    assert_equal 'TwitterDev', user['screen_name']
  end

  def test_friends_ids
    ids = @twitter.friends_ids(user_id: 2244994945)
    assert_instance_of Array, ids
    assert_kind_of Twitter::Cursored, ids
  end

  def test_lists_ownerships
    lists = @twitter.lists_ownerships(user_id: 783214)
    assert_equal %w[ Ads\ &\ Sales Developers Engineering International
                     Media Offices\ &\ Culture Official\ Twitter\ Accounts
                     Support Twitter\ &\ IR ],
                 lists.map {|list| list['name'] }.sort
  end

  def test_lists_members
    members = @twitter.lists_members(list_id: 84839422)
    member_ids = members.map {|member| member['id']}
    [3260518932, 3260514654, 3099993704].each do |id|
      assert_includes member_ids, id
    end
  end

  def test_users_lookup
    users = @twitter.users_lookup(user_ids: [715073, 2244994945])
    assert_equal %w[TwitterDev kejadlen],
                 users.map {|user| user['screen_name'] }.sort
  end

  def test_rate_limited
    conn = Class.new do
      def self.get(*)
        response = { status: 429, headers: { 'rate-limit-reset'=> '56789' } }
        raise Faraday::ClientError.new(nil, response)
      end
    end
    @twitter.instance_variable_set(:@conn, conn)

    assert_raises(Twitter::Client::RateLimitedError) do
      @twitter.users_show(user_id: 12345)
    end
  end
end
