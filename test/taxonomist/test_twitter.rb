require_relative "../test_helper"

require "taxonomist/twitter"

class TestTwitterAuthed < Test
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
