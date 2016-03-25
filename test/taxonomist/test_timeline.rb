require_relative '../test_helper'
require_relative '../twitter_stub'

require 'taxonomist/timeline'

class TestTimeline < Test
  class TimelineStub
    attr_reader :ids

    def initialize
      @ids = 1_337.times.with_object([1]) { |_, ids|
        ids << ids.last + rand(5) + 1
      }.reverse
    end

    def statuses_user_timeline(user_id:, since_id: nil, max_id: nil)
      since_id ||= ids.last - 1
      max_id ||= ids.first
      ids.select {|id| (since_id+1..max_id).cover?(id) }
         .take(200)
         .map {|id| { 'id' => id } }
    end
  end

  def test_timeline
    timeline_stub = TimelineStub.new
    timeline = Timeline.new(timeline_stub, :statuses_user_timeline, nil)

    assert_equal timeline_stub.ids, timeline.to_a.map {|t| t['id'] }
  end
end
