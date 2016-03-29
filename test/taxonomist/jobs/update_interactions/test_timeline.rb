require_relative '../test_job'

require 'taxonomist/jobs/update_interactions/timeline'
require 'taxonomist/twitter'

class Jobs::UpdateInteractions::TestTimeline < TestJob
  def test_timeline
    statuses = [
      { 'id' => 579, 'quoted_status' => { 'user' => { 'id' => 456 }}},
      { 'id' => 468, 'entities' => { 'user_mentions' => []}},
      { 'id' => 357, 'entities' => { 'user_mentions' => [{ 'id' => 123 },
                                                         { 'id' => 789 }]}},
      { 'id' => 248, 'entities' => { 'user_mentions' => [{ 'id' => 123 }]}},
    ]
    responses = [statuses, []]
    TwitterStub.stubs = { statuses_user_timeline: ->(*) { responses.shift } }

    Jobs::UpdateInteractions::Timeline.enqueue(@user.id)

    @user.refresh

    assert_equal 579, @user.tweet_marks['statuses_user_timeline']

    interactions = @user.interactions['statuses_user_timeline']
    assert_equal 2, interactions['123']
    assert_equal 1, interactions['456']
    assert_equal 1, interactions['789']
  end

  def test_rate_limited
    pre_rate_limit = [
      { 'id' => 579, 'quoted_status' => { 'user' => { 'id' => 456 }}},
      { 'id' => 468, 'entities' => { 'user_mentions' => []}},
    ]
    reset_at = Time.now + 42
    post_rate_limit = [
      { 'id' => 357, 'entities' => { 'user_mentions' => [{ 'id' => 123 },
                                                         { 'id' => 789 }]}},
      { 'id' => 248, 'entities' => { 'user_mentions' => [{ 'id' => 123 }]}},
    ]
    responses = [pre_rate_limit, nil, post_rate_limit, []]
    TwitterStub.stubs = {
      statuses_user_timeline: ->(*) {
        result = responses.shift
        raise Twitter::RateLimitedError.new(reset_at: reset_at) unless result

        result
      }
    }

    Jobs::UpdateInteractions::Timeline.enqueue(@user.id)

    @user.refresh

    assert_equal 579, @user.tweet_marks['statuses_user_timeline']

    interactions = @user.interactions['statuses_user_timeline']
    assert_equal 2, interactions['123']
    assert_equal 1, interactions['456']
    assert_equal 1, interactions['789']
  end
end
