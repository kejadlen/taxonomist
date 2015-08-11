require_relative "../test_helper"

require "taxonomist/jobs"

class TestUpdateUser < Test
  FRIEND_IDS = [45, 67, 89]

  class FakeTwitter < Twitter::Authed
    def friends_ids(*)
      FRIEND_IDS
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

    assert_equal FRIEND_IDS, @user.friend_ids
  end
end
