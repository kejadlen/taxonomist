require_relative '../../test_helper'
require_relative '../../twitter_stub'

require 'taxonomist/jobs'

class TestJob < Test
  def setup
    without_warnings do
      @original_twitter = Twitter::Authed
      Twitter.const_set(:Authed, TwitterStub)
    end

    @user = Models::User.create(twitter_id: 1)
  end

  def teardown
    TwitterStub.stubs.clear

    without_warnings do
      Twitter.const_set(:Authed, @original_twitter)
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

