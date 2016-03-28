require_relative '../test_helper'
require_relative '../twitter_stub'

require 'taxonomist/timeline'
require 'taxonomist/twitter'

class TestTimeline < Test
  def test_timeline
    ids = 1_337.times.with_object([1]) { |_, ids|
      ids << ids.last + rand(5) + 1
    }.reverse

    timeline_stub = TimelineStub.new do |user_id:, since_id: nil, max_id: nil|
      since_id ||= ids.last - 1
      max_id ||= ids.first
      ids.select {|id| (since_id+1..max_id).cover?(id) }
         .take(200)
         .map {|id| { 'id' => id } }
    end

    user_id = nil
    timeline = Timeline.new(timeline_stub, :statuses_user_timeline, user_id)

    assert_equal ids, timeline.to_a.map {|t| t['id'] }
    assert_nil timeline.rate_limited
  end

  def test_rate_limited
    reset_at = Time.now + 42
    timeline_stub = TimelineStub.new do |**options|
      raise Twitter::RateLimitedError.new(reset_at: reset_at)
    end

    user_id = nil
    timeline = Timeline.new(timeline_stub, :statuses_user_timeline, user_id)

    assert_equal [], timeline.to_a
    assert_equal reset_at, timeline.rate_limited.reset_at
  end

  class TimelineStub
    def initialize(&block)
      @block = block
    end

    def statuses_user_timeline(user_id:, since_id: nil, max_id: nil)
      @block.call(user_id: user_id, since_id: since_id, max_id: max_id)
    end
  end
end
