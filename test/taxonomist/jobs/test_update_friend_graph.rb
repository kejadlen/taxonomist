require_relative "test_job"

require "taxonomist/jobs/update_friend_graph"

class TestUpdateFriendGraph < TestJob
  def test_update_friend_graph
    friend_ids = [2, 3]

    @user.update(friend_ids: friend_ids)
    friend_ids.each do |id|
      Models::User.create(twitter_id: id)
    end

    Jobs::UpdateFriendGraph.enqueue(@user.id, friend_ids)

    friend_ids.each do |id|
      assert_equal KarateClub::FRIENDS[id], Models::User[twitter_id: id].friend_ids
    end
  end
end
