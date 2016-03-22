require_relative '../test_helper'
require_relative '../twitter_stub'

require 'taxonomist/list'

module Taxonomist
  class TestList < Test
    def test_list
      remote_ids = [2, 4, 6, 8]

      list = List.new(12345, TwitterStub.new(lists_members: remote_ids))
      list.pull!

      assert_equal remote_ids, list.remote_ids
    end
  end
end
