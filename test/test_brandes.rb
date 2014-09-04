require_relative 'test_helper'

require 'twister/graph'

module Twister
  class TestBrandes < Minitest::Test
    karate_gml = File.read(File.expand_path('../karate.gml', __FILE__))
    Brandes.from_gml(karate_gml)
  end
end
