require_relative "test_job"

class TestHydrateFriends < TestJob
  def test_nonexistent_friends
    friends = KarateClub::FRIENDS[@user.twitter_id]
    Jobs::HydrateFriends.enqueue(@user.id, friends)

    friends.each do |friend|
      assert_equal Models::User[twitter_id: friend].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[friend]
    end
  end

  def test_existing_friends
    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    friend_ids.each do |id|
      Models::User.create(twitter_id: id)
    end

    Jobs::HydrateFriends.enqueue(@user.id, friend_ids)

    friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[id]
    end
  end

  def test_existing_and_nonexistent_friends
    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    Models::User.create(twitter_id: friend_ids.first)

    Jobs::HydrateFriends.enqueue(@user.id, friend_ids)

    friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[id]
    end
  end

  def test_users_per_request
    friend_ids = KarateClub::FRIENDS[@user.twitter_id]

    with_const(Jobs::HydrateFriends, :USERS_PER_REQUEST, 2) do
      Jobs::HydrateFriends.enqueue(@user.id, friend_ids)
    end

    friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
        KarateClub::SCREEN_NAMES[id]
    end
  end
end
