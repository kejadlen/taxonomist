require_relative "test_job"

class TestUpdateUser < TestJob
  def test_update_user
    with_job_mock do
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

    with_job_mock do
      Jobs::UpdateUser.enqueue(@user.id)
    end

    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    assert_equal friend_ids.size, Models::User.where(twitter_id: friend_ids).count
  end

  def with_job_mock
    job_mock = Minitest::Mock.new

    original_hydrate_friends = Jobs::HydrateFriends
    original_update_friend_graph = Jobs::UpdateFriendGraph
    without_warnings do
      Jobs.const_set(:HydrateFriends, job_mock)
      Jobs.const_set(:UpdateFriendGraph, job_mock)
    end

    job_mock.expect :enqueue, nil, [@user.id]
    job_mock.expect :enqueue, nil, [@user.id]

    yield
  ensure
    without_warnings do
      Jobs.const_set(:HydrateFriends, original_hydrate_friends)
      Jobs.const_set(:UpdateFriendGraph, original_update_friend_graph)
    end

    job_mock.verify
  end
end
