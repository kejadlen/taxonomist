require_relative '../test_helper'
require_relative '../twitter_stub'

require 'taxonomist/timeline'
require 'taxonomist/twitter'

class TestTimeline < Test
  def test_timeline
    ids = 1_337.times.with_object([1]) { |_, ids|
      ids << ids.last + rand(5) + 1
    }.reverse

    twitter_stub = TwitterStub.new(
      statuses_user_timeline: ->(user_id:, since_id: nil, max_id: nil) {
        since_id ||= ids.last - 1
        max_id ||= ids.first
        ids.select {|id| (since_id+1..max_id).cover?(id) }
          .take(200)
          .map {|id| { 'id' => id } }
      }
    )

    user_id = nil
    timeline = Timeline.new(twitter_stub, :statuses_user_timeline, user_id)
    timeline.fetch!

    assert_equal ids, timeline.statuses.map {|t| t['id'] }
    assert_nil timeline.rate_limited
  end

  def test_rate_limited
    reset_at = Time.now + 42
    twitter_stub = TwitterStub.new(
      statuses_user_timeline: ->(*) {
        raise Twitter::RateLimitedError.new(reset_at: reset_at)
      }
    )

    user_id = nil
    timeline = Timeline.new(twitter_stub, :statuses_user_timeline, user_id)
    timeline.fetch!

    assert_equal [], timeline.statuses
    assert_equal reset_at, timeline.rate_limited.reset_at
  end
end
