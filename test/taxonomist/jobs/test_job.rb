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

  def with_mocked_jobs(jobs)
    job_mock = Minitest::Mock.new
    originals = Hash[jobs.map {|klass,_| [klass, Jobs.const_get(klass)] }]

    without_warnings do
      jobs.each do |klass, args|
        Jobs.const_set(klass, job_mock)
        job_mock.expect :enqueue, nil, args
      end
    end

    yield
  ensure
    job_mock.verify

    without_warnings do
      originals.each do |klass, original|
        Jobs.const_set(klass, original)
      end
    end
  end
end

