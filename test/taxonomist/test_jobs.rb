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

    def users_lookup(*)
      FRIENDS.map(&:to_h).map do |friend|
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
  def test_hydrate_friends
    @user.update(friend_ids: FRIENDS.map(&:id))
    Jobs::HydrateFriends.enqueue(@user.id)

    FRIENDS.each do |friend|
      assert_equal Models::User[twitter_id: friend.id].raw["screen_name"],
                   friend.screen_name
    end
  end
end
