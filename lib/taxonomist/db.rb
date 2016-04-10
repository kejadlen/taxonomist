require "sequel"

Sequel.extension :pg_json_ops
Sequel::Model.plugin :timestamps, update_on_create: true

module Taxonomist
  DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
  DB.extension :pg_array, :pg_json

  module Models
    class Interactions < Sequel::Model(:interactions)
      many_to_one :user
    end

    class User < Sequel::Model
      one_to_many :interactions, class: Interactions

      def name
        raw.fetch('name', '')
      end

      def screen_name
        raw.fetch('screen_name', '')
      end

      def to_s
        "#{screen_name} (#{name})"
      end

      # def graph
      #   graph = self.class.where(twitter_id: self.friend_ids.to_a - [self.twitter_id])
      #                     .select_hash(:twitter_id, :friend_ids)
      #   Hash[graph.map {|id,friend_ids| [id, friend_ids - [self.twitter_id]] }]
      # end
    end

    class List < Sequel::Model; end
  end
end
