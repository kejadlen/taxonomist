require_relative "../test_helper"

require "taxonomist/twitter"

class TestTwitterAuthed < Test
  def self.runnable_methods
    return [] unless ENV.has_key?("TEST_TWITTER")

    super
  end

  def setup
    api_key = ENV.fetch("TWITTER_API_KEY")
    api_secret = ENV.fetch("TWITTER_API_SECRET")
    access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
    access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")

    @twitter = Twitter::Authed.new(api_key: api_key,
                                   api_secret: api_secret,
                                   access_token: access_token,
                                   access_token_secret: access_token_secret)
  end

  def test_authed
    user = @twitter.users_show(user_id: 2244994945)
    assert_equal "TwitterDev", user["screen_name"]
  end

  def test_friends_ids
    ids = @twitter.friends_ids(user_id: 2244994945)
    assert_instance_of Array, ids
    assert_kind_of Twitter::Authed::Cursored, ids
  end

  def test_users_lookup
    users = @twitter.users_lookup(user_ids: [715073, 2244994945])
    assert_equal %w[TwitterDev kejadlen],
                 users.map {|user| user["screen_name"] }.sort
  end

  def test_cursored
    obj = Object.new
    obj.extend(Twitter::Authed::Cursored)
    obj.attributes = { next_cursor: 12345, previous_cursor: 67890 }

    assert_equal 12345, obj.next_cursor
    assert_equal 67890, obj.previous_cursor
  end
end
