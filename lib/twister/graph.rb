require 'set'

module Twister
  Node = Struct.new(:id, :neighbors)

  class Brandes
    def self.from_friend(friend)
      friends = friend.friends.reject {|f| f == friend }
      friend_ids = friends.map(&:twitter_id)
      neighbors = friends.each.with_object({}) do |friend, neighbors|
        neighbors[friend.twitter_id] = friend.friend_ids.select {|id| friend_ids.include?(id) }
      end
      new(neighbors)
    end

    def self.from_gml(gml)
      edges = gml.scan(/edge\s*\[\s*source\s*(\w+)\s*target\s*(\w+)\s*\]/m)
      neighbors = edges.each.with_object({}) do |edge,n|
      end
      p edges
    end

    attr_reader :neighbors

    def initialize(neighbors)
      @neighbors = neighbors
    end

    def invert
      self.class.new(
        vertices.each.with_object({}) do |i,h|
          neighbors[i].each do |j|
            key = [i,j].sort
            next if h.has_key?(key)

            h[key] = []
            neighbors[i].each {|k| h[key] << [i,k].sort }
            neighbors[j].each {|k| h[key] << [j,k].sort }
            h[key].delete(key)
          end
        end
      )
    end

    def betweenness_centrality
      c_b = Hash.new(0)
      b_k = Hash.new(1.0)
      vertices.each do |s|
        stack = []
        p = Hash.new {|h,k| h[k] = [] }
        𝜎 = Hash.new(0); 𝜎[s] = 1
        d = Hash.new; d[s] = 0
        q = [s]
        until q.empty?
          v = q.shift
          stack << v
          neighbors[v].each do |w|
            unless d.has_key?(w)
              q << w
              d[w] = d[v] + 1
            end
            if d[w] == d[v] + 1
              𝜎[w] = 𝜎[w] + 𝜎[v]
              p[w] << v
            end
          end
        end
        𝛿 = Hash.new(0)
        until stack.empty?
          w = stack.pop
          p[w].each {|v| 𝛿[v] = 𝛿[v] + (𝜎[v]/𝜎[w])*(1 + 𝛿[w]) }
          c_b[w] = c_b[w] + 𝛿[w] unless w == s
        end
      end
      c_b
    end

    def vertices
      neighbors.keys
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
