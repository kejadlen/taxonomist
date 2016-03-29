require 'que'

require_relative '../db'
require_relative '../twitter'

module Taxonomist
  module Jobs
    Que.connection = DB

    class Job < Que::Job
      def run_rate_limited(*args, **options)
        raise NotImplementedError
      end

      def run(*args, **options)
        user_id = args.first
        @user = Models::User[user_id]

        @twitter = Twitter::Client::Authed.new(
          api_key: ENV.fetch('TWITTER_API_KEY'),
          api_secret: ENV.fetch('TWITTER_API_SECRET'),
          access_token: user.access_token,
          access_token_secret: user.access_token_secret,
        )

        DB.transaction do
          run_rate_limited(*args[1..-1])
          destroy
        end
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(*args, **options.merge(run_at: e.reset_at))
      end

      private

      attr_reader :twitter, :user
    end
  end
end
