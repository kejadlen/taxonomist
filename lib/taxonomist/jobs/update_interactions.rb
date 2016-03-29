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

        user.interactions[endpoint.to_s] ||= {}
        interactions = user.interactions[endpoint.to_s]

        timeline.statuses.flat_map { |status|
          interactee_ids(status)
        }.map(&:to_s).each do |id|
          interactions[id] ||= 0
          interactions[id] += 1
        end

        user.save

        if timeline.rate_limited
          self.class.enqueue(user.id, since_id, max_id)
        end
      end
    end

    class UpdateInteractions::Timeline < UpdateInteractions
      def endpoint
        :statuses_user_timeline
      end

      def interactee_ids(status)
        user_mentions = Array(status.dig('entities', 'user_mentions'))
        ids = user_mentions.map {|um| um['id'] }
        ids << status.dig('quoted_status', 'user', 'id')
        ids.compact
      end
    end
  end
end
