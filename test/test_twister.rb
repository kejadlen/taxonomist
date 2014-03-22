require 'minitest/autorun'
require 'minitest/pride'
require 'pry'
require 'pry-byebug'

require 'dotenv'
Dotenv.load

require 'twister'

module Twister
  class TestUser < Minitest::Test
    def test_http
      user = Twister::User.new(screen_name: 'kejadlen',
                               access_token: ENV['ACCESS_TOKEN'],
                               access_token_secret: ENV['ACCESS_TOKEN_SECRET'])

      resp = user.connection.get('account/verify_credentials.json')
      assert_equal('kejadlen', resp.body['screen_name'])
    end
  end
end
