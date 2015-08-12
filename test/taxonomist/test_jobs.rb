require_relative "../test_helper"

require "taxonomist/jobs"

class TestUpdateUser < Test
  Friend = Struct.new(:id, :screen_name)

  FRIENDS = [[ 45, "foo" ], [ 67, "bar"], [ 89, "baz" ]].map do |friend|
    Friend.new(*friend)
  end

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
  end

  def setup
    @user = Models::User.create(twitter_id: 123)
  end

  def test_update_user
    job = Jobs::UpdateUser.new
    job.twitter_adapter = FakeTwitter
    job.run(user_id: @user.id)

    @user.refresh

    assert_equal FRIENDS.map(&:id), @user.friend_ids
  end

  def test_hydrate_users
    job = Jobs::HydrateUsers.new
    job.twitter_adapter = FakeTwitter
    job.run(user_id: @user.id, user_ids: FRIENDS.map(&:id))

    FRIENDS.each do |friend|
      assert_equal Models::User[twitter_id: friend.id].raw["screen_name"],
                   friend.screen_name
    end
  end
end
