module Twister
  class InitialFetcher
    attr_reader :connection, :friend

    def initialize(user)
      @connection = user.connection
      @friend = user.friend
    end

    def run
      friend.fetch_friends(connection)
      friend.hydrate_friends(connection)
      friend.friends.each do |friend|
        friend.fetch_friends(connection)
      end
    end
  end
end
