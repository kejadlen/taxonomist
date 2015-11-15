require_relative "test_job"

class TestUpdateUser < TestJob
  MOCKED_JOBS = %i[ HydrateFriends UpdateFriendGraph ]

  def test_update_user
    with_mocked_jobs(MOCKED_JOBS) do
      Jobs::UpdateUser.enqueue(@user.id)
    end

    @user.refresh

    twitter_id = @user.twitter_id
    assert_equal({"id" => twitter_id,
                  "screen_name" => KarateClub::SCREEN_NAMES[twitter_id]},
                 @user.raw)
    assert_equal KarateClub::FRIENDS[@user.twitter_id], @user.friend_ids
  end

  def test_create_friends
    assert_equal 1, Models::User.count

    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    Models::User.create(twitter_id: friend_ids.first)
    assert_equal 2, Models::User.count

    with_mocked_jobs(MOCKED_JOBS) do
      Jobs::UpdateUser.enqueue(@user.id)
    end

    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    assert_equal friend_ids.size, Models::User.where(twitter_id: friend_ids).count
  end
end
