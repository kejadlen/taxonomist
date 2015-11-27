require_relative "test_job"

require "taxonomist/jobs/update_user"

module Taxonomist
  class TestUpdateUser < TestJob
    def setup
      super

      @raw = { "foo" => "bar" }
      @friend_ids = [2, 3, 5, 8]
      @list_ids = [10, 20, 30]
      @lists = @list_ids.map {|id| { "id" => id } }

      @mocked_jobs = {
        UpdateLists: [@user.id, @list_ids],
        HydrateUsers: [@user.id, @friend_ids],
        UpdateFriendGraph: [@user.id, @friend_ids],
      }

      TwitterStub.stubs = {
        users_show: @raw,
        friends_ids: @friend_ids,
        lists_ownerships: @lists,
      }
    end

    def test_update_user
      with_mocked_jobs(@mocked_jobs) do
        Jobs::UpdateUser.enqueue(@user.id)
      end

      @user.refresh
      assert_equal @raw, @user.raw
      assert_equal @friend_ids, @user.friend_ids
      assert_equal @list_ids, @user.list_ids
    end

    def test_create_friends
      assert_equal 1, Models::User.count

      Models::User.create(twitter_id: @friend_ids.first)
      assert_equal 2, Models::User.count

      with_mocked_jobs(@mocked_jobs) do
        Jobs::UpdateUser.enqueue(@user.id)
      end

      assert_equal @friend_ids.size, Models::User.where(twitter_id: @friend_ids).count
    end

    def test_update_lists
      with_mocked_jobs(@mocked_jobs) do
        Jobs::UpdateUser.enqueue(@user.id)
      end

      @lists.each do |list|
        assert_equal list, Models::List[twitter_id: list["id"]].raw
      end
    end
  end
end
