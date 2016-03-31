require_relative '../test_helper'

require 'taxonomist/list_update'

class TestListUpdate < Test
  def setup
    @list_id = 1_337

    @twitter_mock = Minitest::Mock.new
    @twitter_mock.expect :lists_members, [1, 2, 3, 7, 8, 9], [{ list_id: @list_id }]

    ids = (3..7).to_a
    @list_update = ListUpdate.new(@twitter_mock, @list_id, ids: ids)
  end

  def test_diff
    diff = @list_update.diff

    assert_equal [4, 5, 6], diff[:insertions]
    assert_equal [1, 2, 8, 9], diff[:deletions]
  end

  def test_commit!
    @twitter_mock.expect :lists_members_create_all,
                         nil,
                         [{ list_id: @list_id, user_ids: [4, 5, 6] }]
    @twitter_mock.expect :lists_members_destroy_all,
                         nil,
                         [{ list_id: @list_id, user_ids: [1, 2, 8, 9] }]

    @list_update.commit!

    @twitter_mock.verify
  end
end
