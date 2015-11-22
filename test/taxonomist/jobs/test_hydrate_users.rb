require_relative "test_job"

require "taxonomist/jobs/hydrate_users"

class TestHydrateUsers < TestJob
  def setup
    super

    friend_ids = KARATE_CLUB[@user.twitter_id]
    @user.update(friend_ids: friend_ids)

    friend_ids.each do |id|
      Models::User.create(twitter_id: id)
    end
  end

  def test_hydrate_users
    Jobs::HydrateUsers.enqueue(@user.id, @user.friend_ids)

    @user.friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   TwitterStub::SCREEN_NAMES[id]
    end
  end

  def test_users_per_request
    with_const(Jobs::HydrateUsers, :USERS_PER_REQUEST, 2) do
      Jobs::HydrateUsers.enqueue(@user.id, @user.friend_ids)
    end

    @user.friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
        TwitterStub::SCREEN_NAMES[id]
    end
  end
end
