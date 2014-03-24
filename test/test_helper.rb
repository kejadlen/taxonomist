require 'minitest/autorun'
require 'minitest/pride'
require 'pry'
require 'pry-byebug'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'dotenv'
Dotenv.load
# ENV['DATABASE_URL'] = 'sqlite://development'

require 'sequel'
Sequel.extension :migration
DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
Sequel::Migrator.run(DB, 'db/migrations')

module Twister
  class Test < Minitest::Test
    def run
      result = nil
      Sequel::Model.db.transaction(rollback: :always) { result = super }
      result
    end
  end
end
