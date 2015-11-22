require_relative "karate_club"

module Taxonomist
  class TwitterStub
    SCREEN_NAMES = {
      1 => 'Alice',
      2 => 'Bob',
      3 => 'Charlie',
    }

    attr_reader :friends

    def initialize(*)
    end

    def friends_ids(user_id:)
      KARATE_CLUB[user_id]
    end

    def users_lookup(user_ids:)
      user_ids.map {|id| raw(id) }
    end

    def users_show(user_id:)
      raw(user_id)
    end

    def raw(id)
      { 'id' => id, 'screen_name' => SCREEN_NAMES[id] }
    end
  end
end
