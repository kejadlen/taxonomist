require_relative "karate_club"

module Taxonomist
  class TwitterStub
    class << self
      attr_accessor :stubs
    end

    attr_reader :stubs

    def initialize(stubs={})
      @stubs = (self.class.stubs || {}).merge(stubs)
    end

    def method_missing(name, *args)
      answer = self.stubs[name]
      case answer
      when Proc
        answer.call(*args)
      else
        answer
      end
    end

    def respond_to_missing?(name, include_private=false)
      self.stubs.has_key?(name)
    end
  end
end
