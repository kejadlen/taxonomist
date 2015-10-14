require_relative "test_job"

class TestUpdateUser < TestJob
  def test_update_user
    Jobs::UpdateUser.enqueue(@user.id)

    @user.refresh

    twitter_id = @user.twitter_id
    assert_equal({"id" => twitter_id,
                  "screen_name" => KarateClub::SCREEN_NAMES[twitter_id]},
                 @user.raw)
    assert_equal KarateClub::FRIENDS[@user.twitter_id], @user.friend_ids
  end
end

