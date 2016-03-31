require "sequel"

Sequel.extension :pg_json_ops
Sequel::Model.plugin :timestamps, update_on_create: true

module Taxonomist
  DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
  DB.extension :pg_array, :pg_json

  module Models
    class User < Sequel::Model
      def name
        raw.fetch('name', '')
      end

      def screen_name
        raw.fetch('screen_name', '')
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
