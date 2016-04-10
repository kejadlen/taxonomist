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
        interactions = Models::Interactions.find_or_create(user: user,
                                                           endpoint: endpoint.to_s)

        since_id ||= interactions.since_id

        timeline = Taxonomist::Timeline.new(twitter,
                                            endpoint,
                                            user.twitter_id,
                                            since_id,
                                            max_id)
        timeline.fetch!

        timeline.statuses.flat_map { |status|
          interactee_ids(status)
        }.map(&:to_s).each do |id|
          interactions.counts[id] ||= 0
          interactions.counts[id] += 1
        end

        unless timeline.statuses.empty?
          max_id = timeline.statuses.first['id']
          interactions.since_id = [ since_id, max_id ].compact.max
        end

        if timeline.rate_limited
          run_at = timeline.rate_limited.reset_at
          self.class.enqueue(user.id, since_id, max_id, run_at: run_at)
        end

        interactions.save
        user.save
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
