module Twister
  class Friend < Sequel::Model
    one_to_one :user

    def friends
      self.class.where(twitter_id: friend_ids.to_a)
    end

    def fetch_friends(connection)
      LOG.debug("Fetching friends for #{twitter_id}")

      response = connection.get('friends/ids.json', user_id: twitter_id)
      update(friend_ids: response.body['ids'].map(&:to_i))
    end

    def hydrate_friends(connection)
      friends.where(screen_name: nil).each_slice(100) do |slice|
        response = connection.get('users/lookup.json',
                                  user_id: slice.map(&:twitter_id).join(','))
        response.body.each do |user|
          Friend.where(twitter_id: user['id'])
                .update(screen_name: user['screen_name'])
        end
      end
    end
  end
end
