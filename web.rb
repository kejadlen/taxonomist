require 'json'
require 'set'

require 'dotenv'
Dotenv.load

require 'sinatra'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'twister'

get '/' do
  erb :index
end

get '/friends.json' do
  friend = Twister::User[1].friend
  friend_ids = Set.new(friend.friend_ids)
  friend_ids << friend.twitter_id
  friends = friend_ids.map {|id| Twister::Friend.first(twitter_id: id) }

  result = { nodes: [], links: [] }

  nodes = {}
  friends.each.with_index do |friend, index|
    result[:nodes] << { twitter_id: friend.twitter_id,
                        screen_name: friend.screen_name }
    nodes[friend.twitter_id] = index
  end

  friends.each do |friend|
    friend.friend_ids.select {|id| nodes.has_key?(id) }.each do |id|
    # friend.friend_ids.each do |id|
      result[:links] << { source: nodes[friend.twitter_id],
                          target: nodes[id] }
    end
    # nodes.delete(friend.twitter_id)
  end

  JSON.dump(result)
end
