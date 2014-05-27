require 'dotenv'
Dotenv.load

require 'minitest/autorun'
require 'minitest/pride'
require 'pry'
require 'pry-byebug'
require 'pry-rescue/minitest'
require 'sequel'
require 'vcr'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr'
  c.hook_into :webmock
end

module Twister
  class DBTest < Minitest::Test
    def run
      result = nil
      Sequel::Model.db.transaction(rollback: :always) do
        VCR.use_cassette('twister') do
          result = super
        end
      end
      result
    end
  end
end
