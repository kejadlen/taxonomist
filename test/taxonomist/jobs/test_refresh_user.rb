require_relative 'test_job'

require 'taxonomist/jobs/refresh_user'

module Taxonomist
  class TestRefreshUser < TestJob
    def setup
      super

      @raw = { 'foo' => 'bar' }
      @friend_ids = [2, 3, 5, 8]

      @mocked_jobs = {
        HydrateUsers: [@user.id, @friend_ids],
        RefreshFriendGraph: [@user.id, @friend_ids],
      }

      TwitterStub.stubs = {
        users_show: @raw,
        friends_ids: @friend_ids,
      }
    end

    def test_update_user
      with_mocked_jobs(@mocked_jobs) do
        Jobs::RefreshUser.enqueue(@user.id)
      end

      @user.refresh
      assert_equal @raw, @user.raw
      assert_equal @friend_ids, @user.friend_ids
    end

    def test_create_friends
      assert_equal 1, Models::User.count

      Models::User.create(twitter_id: @friend_ids.first)
      assert_equal 2, Models::User.count

      with_mocked_jobs(@mocked_jobs) do
        Jobs::RefreshUser.enqueue(@user.id)
      end

      assert_equal @friend_ids.size, Models::User.where(twitter_id: @friend_ids).count
    end
  end
end
