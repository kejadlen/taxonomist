require_relative "test_job"

require "taxonomist/jobs/update_friend_graph"

class TestUpdateFriendGraph < TestJob
  def test_update_friend_graph
    friend_graph = { 2 => [1, 3, 5], 3 => [2, 4, 6] }

    @user.update(friend_ids: friend_graph.keys)
    friend_graph.each do |id, _|
      Models::User.create(twitter_id: id)
    end
    TwitterStub.stubs = { friends_ids: ->(user_id:) { friend_graph[user_id] } }

    Jobs::UpdateFriendGraph.enqueue(@user.id, friend_graph.keys)

    friend_graph.each do |friend_id, friend_ids|
      assert_equal friend_ids, Models::User[twitter_id: friend_id].friend_ids
    end
  end
end
