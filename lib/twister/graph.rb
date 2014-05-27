require 'set'

module Twister
  class FloydWarshall
    attr_reader :vertices, :edges

    def initialize(vertices, edges)
      @vertices = vertices
      @edges = edges
    end

    def shortest_paths
      dist = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = Float::INFINITY } }
      vertices.each do |v|
        dist[v][v] = 0
      end
      edges.each do |(u,v),w|
        dist[u][v] = w
      end
      vertices.each do |k|
        vertices.each do |i|
          vertices.each do |j|
            dist[i][j] = dist[i][k] + dist[k][j] if dist[i][j] > dist[i][k] + dist[k][j]
          end
        end
      end
      dist
    end
  end

  class Graph
    attr_reader :nodes, :links

    def initialize(friend)
      friend_ids = friend.friend_ids.reject {|id| id == friend.twitter_id }
      @nodes = Hash[friend_ids.map.with_index {|id,i| [id, i] }]

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
