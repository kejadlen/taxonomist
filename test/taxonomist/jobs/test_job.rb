require_relative "../../test_helper"
require_relative "../../karate_club"

require "taxonomist/jobs"

class TestJob < Test
  def setup
    without_warnings do
      @original_twitter_adapter = Jobs::Job::TWITTER_ADAPTER
      Jobs::Job.const_set(:TWITTER_ADAPTER, KarateClub)
    end

    @user = Models::User.create(twitter_id: 1)
    @karate_club = KarateClub.new
  end

  def teardown
    without_warnings do
      Jobs::Job.const_set(:TWITTER_ADAPTER, @original_twitter_adapter)
    end
  end
end

