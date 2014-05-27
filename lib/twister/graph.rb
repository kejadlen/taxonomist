require 'set'

module Twister
  class Graph
    attr_reader :nodes, :links

    def initialize(friend)
      @nodes = friend.friend_ids.reject {|id| id == friend.twitter_id }
      @links = friend.friends.reject {|f| f == friend }
                             .each.with_object(Set.new) do |friend, links|
        friend.friend_ids.reject {|id| id == friend.twitter_id }
                         .each do |friend_id|
          links << [friend.twitter_id, friend_id]
          links << [friend_id, friend.twitter_id]
        end
      end
    end

    def betweenness
      fw = FloydWarshall.new(nodes,
                             links.each.with_object({}) {|l,h| h[l] = 1 })
      fw.calculate!
    end
  end

  class FloydWarshall
    attr_reader :vertices, :edges, :dist, :path_tree

    def initialize(vertices, edges)
      @vertices = vertices
      @edges = edges

      @dist = Hash.new {|h,k| h[k] = Float::INFINITY }
      @path_tree = Hash.new
    end

    def calculate!
      vertices.each do |v|
        dist[[v,v]] = 0
      end
      edges.each do |(u,v),w|
        dist[[u,v]] = w
        path_tree[[u,v]] = v
      end
      vertices.each do |k|
        vertices.each do |i|
          vertices.each do |j|
            if dist[[i,k]] + dist[[k,j]] < dist[[i,j]]
              dist[[i,j]] = dist[[i,k]] + dist[[k,j]]
              path_tree[[i,j]] = path_tree[[i,k]]
            end
          end
        end
      end
    end

    def path(u, v)
      return [] if path_tree[[u,v]].nil?

      path = [u]
      path << path_tree[[path.last,v]] while path.last != v
      path
    end
  end
end
