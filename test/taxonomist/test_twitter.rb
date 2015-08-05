require "minitest"
require "pry"

require "dotenv"
Dotenv.load
Dotenv.load(".test.envrc")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "taxonomist"

module Taxonomist
  class TestTwitterAuthed < Minitest::Test
    def test_twitter_authed
      return unless ENV.has_key?("TEST_TWITTER")

      api_key = ENV.fetch("TWITTER_API_KEY")
      api_secret = ENV.fetch("TWITTER_API_SECRET")
      access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
      access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")

      twitter = Twitter::Authed.new(api_key: api_key,
                                    api_secret: api_secret,
                                    access_token: access_token,
                                    access_token_secret: access_token_secret)
      user = twitter.users_show(user_id: 2244994945)
      assert_equal "TwitterDev", user["screen_name"]
    end
  end
end
