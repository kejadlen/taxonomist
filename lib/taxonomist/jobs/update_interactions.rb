require_relative 'job'

require_relative '../timeline'

module Taxonomist
  module Jobs
    class UpdateInteractions < Job
      def counts
        raise NotImplementedError
      end

      def run_rate_limited(endpoint, since_id=nil, max_id=nil)
        timeline = Timeline.new(twitter,
                                endpoint,
                                user.twitter_id,
                                since_id,
                                max_id)
        timeline.fetch!

        max_id = timeline.statuses.first['id']
        user.tweet_marks[endpoint.to_s] = [
          user.tweet_marks.fetch(endpoint.to_s, 0), max_id
        ].max

        timeline.statuses.each do |status|
          user_mentions = Array(status.dig('entities', 'user_mentions'))
          ids = user_mentions.map {|um| um['id'] }
          ids << status.dig('quoted_status', 'user', 'id')
          ids.compact!

          ids.map(&:to_s).each do |id|
            user.interactions[id] ||= 0
            user.interactions[id] += 1
          end
        end

        user.save

        if timeline.rate_limited
          self.class.enqueue(user.id, endpoint, since_id, max_id)
        end
      end
    end
  end
end
