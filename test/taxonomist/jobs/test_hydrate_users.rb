require_relative "test_job"

require "taxonomist/jobs/hydrate_users"

module Taxonomist
  class TestHydrateUsers < TestJob
    def setup
      super

      @friend_ids = [2, 3, 5, 8]
      @user.update(friend_ids: @friend_ids)

      @friend_ids.each do |id|
        Models::User.create(twitter_id: id)
      end

      @users = @friend_ids.map do |id|
        { "id" => id, "screen_name" => "name_#{id}" }
      end
      TwitterStub.stubs = { users_lookup: @users }
    end

    def test_hydrate_users
      Jobs::HydrateUsers.enqueue(@user.id, @user.friend_ids)

      @user.friend_ids.each do |id|
        assert_equal "name_#{id}", Models::User[twitter_id: id].raw["screen_name"]
      end
    end

    def test_users_per_request
      with_const(Jobs::HydrateUsers, :USERS_PER_REQUEST, 2) do
        Jobs::HydrateUsers.enqueue(@user.id, @user.friend_ids)
      end

      @user.friend_ids.each do |id|
        assert_equal "name_#{id}", Models::User[twitter_id: id].raw["screen_name"]
      end
    end
  end
end
