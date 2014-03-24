require_relative 'test_helper'

require 'twister'

module Twister
  class TestUser < Test
    def setup
      @user = Twister::User.new(screen_name: 'kejadlen',
                                access_token: ENV['ACCESS_TOKEN'],
                                access_token_secret: ENV['ACCESS_TOKEN_SECRET'])
    end

    def test_http
      resp = @user.connection.get('account/verify_credentials.json')
      assert_equal('kejadlen', resp.body['screen_name'])
    end

    def test_friend
      @user.save
      binding.pry
    end
  end
end
