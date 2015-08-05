require "minitest"
require "pry"

require "dotenv"
Dotenv.load
Dotenv.load(".test.envrc")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "taxonomist"

module Taxonomist
  class TestAuthedTwitter < Minitest::Test
    def test_twitter
      return unless ENV['TEST_TWITTER']

      api_key = ENV["TWITTER_API_KEY"]
      api_secret = ENV["TWITTER_API_SECRET"]
      access_token = ENV["TWITTER_ACCESS_TOKEN"]
      access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]

      twitter = Twitter::Authed.new(api_key: api_key,
                                    api_secret: api_secret,
                                    access_token: access_token,
                                    access_token_secret: access_token_secret)
      user = twitter.users_show(user_id: 2244994945)
      assert_equal "TwitterDev", user.screen_name
    end
  end
end
