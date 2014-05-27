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
      fw.calculate!

      assert_equal(2, fw.dist[[2,3]])
      assert_equal(3, fw.dist[[4,1]])
      assert_equal(1, fw.dist[[4,3]])
      assert_equal(0, fw.dist[[1,4]])
      assert_equal(4, fw.dist[[2,4]])
      assert_equal(1, fw.dist[[3,2]])
      assert_equal(5, fw.dist[[3,1]])
      assert_equal(-1, fw.dist[[1,2]])

      assert_equal([2,1,3], fw.path(2,3))
      assert_equal([4,2,1,3], fw.path(4,3))
      assert_equal([2,1,3,4], fw.path(2,4))
      assert_equal([1,3,4,2], fw.path(1,2))
    end
  end
end
