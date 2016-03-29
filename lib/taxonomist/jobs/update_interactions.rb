require_relative 'job'

require_relative '../timeline'

module Taxonomist
  module Jobs
    class UpdateInteractions < Job
      def endpoint
        raise NotImplementedError
      end

      def interactee_ids(status)
        raise NotImplementedError
      end

      def run_rate_limited(since_id=nil, max_id=nil)
        timeline = Taxonomist::Timeline.new(twitter,
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
          interactee_ids(status).map(&:to_s).each do |id|
            user.interactions[id] ||= 0
            user.interactions[id] += 1
          end
        end

        user.save

        if timeline.rate_limited
          self.class.enqueue(user.id, since_id, max_id)
        end
      end
    end
  end
end
