require 'set'

module Twister
  class Graph
    attr_reader :nodes, :links

    def initialize(friend)
      @nodes = Hash[friend.friend_ids.map.with_index {|id,i| [id, i] }]
      @links = Set.new
      friend.friends.each do |friend|
        friend.friend_ids.reject {|id| id == friend.twitter_id }.each do |id|
          @links << [friend.twitter_id, id]
          @links << [id, friend.twitter_id]
        end
      end
    end

    def floyd_warshall
      dist = Hash.new(Float::INFINITY)
      nodes.each {|node| dist[[node, node]] = 0 }
      links.each {|u,v| dist[[u,v]] = 1; dist[[v,u]] = 1 }
      nodes.each do |k|
        nodes.each do |i|
          nodes.each do |j|
            if dist[[i,j]] > dist[[i,k]] + dist[[k,j]]
              d = dist[[i,k]] + dist[[k,j]]
              dist[[i,j]] = d
              dist[[j,i]] = d
            end
          end
        end
      end
      dist
    end
  end
end
