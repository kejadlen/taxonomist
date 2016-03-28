require "que"

require_relative "../db"
require_relative "../twitter"

module Taxonomist
  module Jobs
    Que.connection = DB

    class Job < Que::Job
      attr_accessor :twitter, :user

      def run_rate_limited(*args, **options)
        raise NotImplementedError
      end

      def run(*args, **options)
        user_id = args.first
        self.user = Models::User[user_id]

        api_key = ENV.fetch('TWITTER_API_KEY')
        api_secret = ENV.fetch('TWITTER_API_SECRET')
        access_token = self.user.access_token
        access_token_secret = self.user.access_token_secret
        self.twitter = Twitter::Authed.new(api_key: api_key,
                                           api_secret: api_secret,
                                           access_token: access_token,
                                           access_token_secret: access_token_secret)

        DB.transaction do
          self.run_rate_limited(*args[1..-1])
          destroy
        end
      rescue Twitter::RateLimitedError => e
        self.class.enqueue(*args, **options.merge(run_at: e.reset_at))
      end
    end
  end
end
