require 'letters'
require 'pry'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'taxonomist'
include Taxonomist

class Interactions
  INTERACTIONS = { timeline: 'statuses_user_timeline',
                   dms: 'direct_messages_sent',
                   favorites: 'favorites_list' }

  def initialize(user_id, list_id)
    @user = Models::User[user_id]
    @list_id = list_id
    @twitter = Twitter::Client::Authed.new(
      api_key: ENV.fetch('TWITTER_API_KEY'),
      api_secret: ENV.fetch('TWITTER_API_SECRET'),
      access_token: @user.access_token,
      access_token_secret: @user.access_token_secret,
    )
    @friends = Hash[
      Models::User.where(twitter_id: @user.friend_ids.to_a).map { |u|
        [ u.twitter_id, "#{u.screen_name} (#{u.name})" ]
      }
    ]
    @filter = ->(_, interactions) { interactions.keys }
  end

  def filter=(filter)
    @filter = filter
    remove_instance_variable(:@ids) if defined?(@ids)
    list_update.ids = ids
  end

  def list_update
    return @list_update if defined?(@list_update)

    @list_update = ListUpdate.new(@twitter, @list_id, ids: ids)
  end

  def pretty_diff
    list_update.diff.map { |type, ids|
      pretty_ids(ids).map { |pretty|
        "#{type == :insertions ? ?+ : ?-} #{pretty}"
      }
    }
  end

  def pretty_ids(ids)
    ids.map { |id| @friends[id] }
  end

  private

  def ids
    return @ids if defined?(@ids)

    @ids = INTERACTIONS.flat_map { |type, key|
      @filter.call(type, @user.interactions[key])
    }.uniq.map(&:to_i) & @user.friend_ids
  end
end

user_id = 1
list_id = 714925948638875648
interactions = Interactions.new(user_id, list_id)
interactions.filter = ->(type, interactions) {
  interactions.keys[0,interactions.size/5]
}

puts interactions.pretty_diff
# interactions.list_update.commit!

Pry.start
