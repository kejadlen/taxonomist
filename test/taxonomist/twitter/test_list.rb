require_relative '../../test_helper'

require 'taxonomist/twitter/list'

class TestTwitterList < Test
  def test_twitter_list
    list_id = 1_337
    twitter_mock = Minitest::Mock.new
    twitter_mock.expect :lists_members, [1, 2, 3, 7, 8, 9], [ list_id ]
    list = Twitter::List.new(twitter_mock, list_id)

    twitter_mock.expect :lists_members_create_all,
                        nil,
                        [{ list_id: list_id, user_id: [4, 5, 6] }]
    twitter_mock.expect :lists_members_destroy_all,
                        nil,
                        [{ list_id: list_id, user_id: [1, 2, 8, 9] }]
    list.update!((3..7).to_a)

    twitter_mock.verify
  end
end
