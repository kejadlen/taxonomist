require_relative "../test_helper"
require_relative "../karate_club"

module Taxonomist
  class TestUser < Test
    # def test_friend_graph
    #   KARATE_CLUB.each do |id, friend_ids|
    #     Models::User.create(twitter_id: id, friend_ids: friend_ids)
    #   end

    #   user = Models::User[twitter_id: 1]
    #   graph = user.graph

    #   refute_includes graph.keys, user.twitter_id
    #   graph.each do |_, friends|
    #     refute_includes friends, user.twitter_id
    #   end
    # end
  end
end
