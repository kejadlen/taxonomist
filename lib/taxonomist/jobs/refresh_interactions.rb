require_relative 'job'

require_relative '../timeline'

module Taxonomist
  module Jobs
    class RefreshInteractions < Job
      def self.enqueue_children(user_id)
        ObjectSpace.each_object(Class)
                   .select { |klass| klass < self }
                   .each do |klass|
          klass.enqueue(user_id)
        end
      end

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

    class RefreshInteractions::Timeline < RefreshInteractions
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

    class RefreshInteractions::DirectMessages < RefreshInteractions
      def endpoint
        :direct_messages_sent
      end

      def interactee_ids(status)
        [status.dig('recipient', 'id')].compact
      end
    end

    class RefreshInteractions::Favorites < RefreshInteractions
      def endpoint
        :favorites_list
      end

      def interactee_ids(status)
        [status.dig('user', 'id')].compact
      end
    end
  end
end
