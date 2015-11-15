require_relative "test_job"

class TestHydrateFriends < TestJob
  def setup
    super

    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    @user.update(friend_ids: friend_ids)
    friend_ids.each do |id|
      Models::User.create(twitter_id: id)
    end
  end

  def test_hydrate_friends
    Jobs::HydrateFriends.enqueue(@user.id)

    @user.friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[id]
    end
  end

  def test_users_per_request
    with_const(Jobs::HydrateFriends, :USERS_PER_REQUEST, 2) do
      Jobs::HydrateFriends.enqueue(@user.id)
    end

    @user.friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
        KarateClub::SCREEN_NAMES[id]
    end
  end
end
