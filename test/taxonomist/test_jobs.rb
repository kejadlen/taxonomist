require_relative "../test_helper"

require "taxonomist/jobs"

class TestJob < Test
  Friend = Struct.new(:id, :screen_name)

  FRIENDS = [[ 45, "foo" ], [ 67, "bar"], [ 89, "baz" ]].map do |friend|
    Friend.new(*friend)
  end

  INFO = { 'screen_name' => 'John Doe' }

  class FakeTwitter < Twitter::Authed
    def friends_ids(*)
      FRIENDS.map(&:id)
    end

    def users_lookup(user_ids:)
      FRIENDS.select {|friend| user_ids.include?(friend.id) }
             .map(&:to_h)
             .map do |friend|
               friend.each.with_object({}) do |(k,v),h|
                 h[k.to_s] = v
               end
             end
    end

    def users_show(*)
      INFO
    end
  end

  class Jobs::Job
    def twitter_adapter
      FakeTwitter
    end
  end

  def setup
    @user = Models::User.create(twitter_id: 123)
  end
end

class TestUpdateUser < TestJob
  def test_update_user
    Jobs::UpdateUser.enqueue(@user.id)

    @user.refresh

    assert_equal INFO, @user.raw
    assert_equal FRIENDS.map(&:id), @user.friend_ids
  end
end

class TestHydrateFriends < TestJob
  class LimitedHydrateFriends < Jobs::HydrateFriends
    def users_per_request
      2
    end
  end

  def test_nonexistent_friends
    Jobs::HydrateFriends.enqueue(@user.id, FRIENDS.map(&:id))

    FRIENDS.each do |friend|
      assert_equal Models::User[twitter_id: friend.id].raw["screen_name"],
                   friend.screen_name
    end
  end

  def test_existing_friends
    FRIENDS.each do |friend|
      Models::User.create(twitter_id: friend.id)
    end

    Jobs::HydrateFriends.enqueue(@user.id, FRIENDS.map(&:id))

    FRIENDS.each do |friend|
      assert_equal Models::User[twitter_id: friend.id].raw["screen_name"],
                   friend.screen_name
    end
  end

  def test_existing_and_nonexistent_friends
    friend = FRIENDS.first
    Models::User.create(twitter_id: friend.id)

    Jobs::HydrateFriends.enqueue(@user.id, FRIENDS.map(&:id))

    FRIENDS.each do |friend|
      assert_equal Models::User[twitter_id: friend.id].raw["screen_name"],
                   friend.screen_name
    end
  end

  def test_users_per_request
    LimitedHydrateFriends.enqueue(@user.id, FRIENDS.map(&:id))

    FRIENDS.each do |friend|
      assert_equal Models::User[twitter_id: friend.id].raw["screen_name"],
                   friend.screen_name
    end
  end
end
