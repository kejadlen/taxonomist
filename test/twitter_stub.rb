require_relative "karate_club"

module Taxonomist
  class TwitterStub
    class << self
      attr_accessor :stubs
    end

    def initialize(*)
      self.class.stubs ||= {}
    end

    def method_missing(name, *args)
      self.class.stubs[name]
    end

    def respond_to_missing?(name, include_private=false)
      self.class.stubs.has_key?(name)
    end
  end
end
