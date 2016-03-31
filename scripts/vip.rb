$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'taxonomist'
include Taxonomist

class VIP
  USER_ID = 1
  LIST_ID = 714925948638875648

  INTERACTIONS = { timeline: 'statuses_user_timeline',
                   dms: 'direct_messages_sent',
                   favorites: 'favorites_list' }

  attr_reader *%i[ user timeline dms favorites users twitter remote_ids ]
  attr_accessor *%i[ cutoffs ]

  def initialize
    @user = Models::User[USER_ID]

    ids = user.interactions.values.flat_map(&:keys).map(&:to_i)
    @users = Hash[
      Models::User.where(twitter_id: ids).map { |u|
        [ u.twitter_id, "#{u.screen_name} (#{u.name})" ]
      }
    ]

    @twitter = Twitter::Client::Authed.new(
      api_key: ENV.fetch('TWITTER_API_KEY'),
      api_secret: ENV.fetch('TWITTER_API_SECRET'),
      access_token: user.access_token,
      access_token_secret: user.access_token_secret,
    )

    @remote_ids = twitter.lists_members(list_id: LIST_ID)
  end

  INTERACTIONS.each do |interaction, key|
    define_method(interaction) do
      user.interactions[key]
        .sort_by(&:last)
        .map { |id, count|
        [count, users[id.to_i]]
      }.reverse
    end
  end

  def list_update(&block)
    ids = INTERACTIONS.flat_map { |interaction, key|
      user.interactions[key]
        .select { |id, count|
        block.call(interaction, id, count)
      }.map(&:first)
    }.map(&:to_i)
     .uniq
    ids &= user.friend_ids

    ListUpdate.new(twitter, LIST_ID, ids: ids)
  end
end

def greater_than(count)
  ->(_,_,c) { c > count }
end

vip = VIP.new

require 'pry'
Pry.start
