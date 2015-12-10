module Taxonomist

  # An implementation of the Speaker-listener Label Propagation Algorithm
  # described in http://arxiv.org/pdf/1109.5720.pdf.
  class SLPA
    attr_reader :graph
    attr_accessor :memory, :t, :r

    # "In general, SLPA produces relatively stable outputs, independent of
    # network size or structure, when T is greater than 20."
    def initialize(graph, t: 25, r: 0.33)
      @graph, @t, @r = graph, t, r

      self.evolve!
    end

    # Stage 1: initialization
    def reset!
      self.memory = Hash.new {|h,k| h[k] = [k]}
    end

    # Stage 2: evolution
    def evolve!
      self.reset!

      self.t.times do
        self.graph.keys.shuffle.each do |listener|
          speakers = self.graph[listener]
          next if speakers.nil? || speakers.empty?

          labels = speakers.map {|speaker| self.memory[speaker].sample }
          label = labels.group_by(&:itself).max_by {|_,v| v.size }.first
          self.memory[listener] << label
        end
      end
    end

    # Stage 3: post-processing
    def communities
      self.graph.keys.each.with_object(Hash.new {|h,k| h[k] = [] }) do |node, communities|
        labels = self.memory[node]
        labels = labels.group_by(&:itself)
                       .map {|label,labels| [label, labels.count]}
                       .select {|label,count| count.to_f / labels.count > self.r }
        labels.each do |label,_|
          communities[label] << node
        end
      end
    end
  end
end
