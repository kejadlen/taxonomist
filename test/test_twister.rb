require_relative 'test_helper'

require 'twister'

module Twister
  class TestUser < Test
    def setup
      @user = Twister::User.create(access_token: ENV['ACCESS_TOKEN'],
                                   access_token_secret: ENV['ACCESS_TOKEN_SECRET'])
    end

    def test_http
      resp = @user.connection.get('account/verify_credentials.json')
      assert_equal('kejadlen', resp.body['screen_name'])
    end

  end

  class TestFriend < Test
    def setup
      @user = Twister::User.create(access_token: ENV['ACCESS_TOKEN'],
                                   access_token_secret: ENV['ACCESS_TOKEN_SECRET'])
    end

    def test_fetch_friends
      @user.save
      refute_nil @user.friend

      @user.friend.fetch_friends
      binding.pry
    end
  end
end
