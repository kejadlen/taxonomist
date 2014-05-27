require_relative 'test_helper'

require 'twister/graph'

module Twister
  class TestFloydWarshall < Minitest::Test
    def test_shortest_paths
      fw = Twister::FloydWarshall.new([1, 2, 3, 4],
                                      { [1, 3] => -2,
                                        [2, 1] => 4,
                                        [2, 3] => 3,
                                        [3, 4] => 2,
                                        [4, 2] => -1 })

      result = fw.shortest_paths
      assert_equal(2, result[2][3])
      assert_equal(3, result[4][1])
      assert_equal(1, result[4][3])
      assert_equal(0, result[1][4])
      assert_equal(4, result[2][4])
      assert_equal(1, result[3][2])
      assert_equal(5, result[3][1])
      assert_equal(-1, result[1][2])
    end
  end
end
