require_relative 'test_job'

require 'taxonomist/jobs/refresh_lists'

module Taxonomist
  class TestRefreshLists < TestJob
    def setup
      super

      to_raw = ->(*ids) { ids.map {|id| { 'id' => id } } }
      @lists = {
        1 => to_raw[10, 20, 30],
        3 => to_raw[1, 2, 3],
        5 => to_raw[2, 4, 8],
      }

      @lists.each do |list_id, _|
        Models::List.create(twitter_id: list_id)
      end

      TwitterStub.stubs = {
        lists_members: ->(list_id:) { @lists[list_id] }
      }
    end

    def test_refresh_lists
      Jobs::RefreshLists.enqueue(@user.id, @lists.keys)

      @lists.each do |list_id, members|
        member_ids = members.map {|member| member['id']}
        assert_equal member_ids, Models::List[twitter_id: list_id].member_ids

        members.each do |member|
          assert_equal member, Models::User[twitter_id: member['id']].raw
        end
      end
    end
  end
end
