require_relative "../test_helper"
require_relative "../karate_club"

require "taxonomist/slpa"

module Taxonomist
  class TestSLPA < Test
    def test_slpa
      graph = Hash[KARATE_CLUB.map {|id,friends| [id, friends - [1]]}]
      graph.delete(1)

      slpa = SLPA.new(graph)
      communities = slpa.communities.values

      assert_includes communities, [12]
      assert_in_delta 5, communities.count, 2
      assert communities.any? {|community| (community & [5, 6, 7, 11, 17]).count >= 4 }
    end
  end
end
