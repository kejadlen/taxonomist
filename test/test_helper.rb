require "minitest/autorun"
require "letters"
require "pry"
require "que"
require "sequel"

require "dotenv"
Dotenv.overload(".test.envrc")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "taxonomist/db"
Que.connection = Taxonomist::DB
Que.migrate!
Que.mode = :sync

if ENV.has_key?("DEBUG")
  require "logger"
  Taxonomist::DB.loggers << Logger.new($stdout)
end

module Taxonomist
  class Test < Minitest::Test
    def run(*args, &block)
      Sequel::Model.db.transaction(rollback: :always, auto_savepoint: true) do
        super
      end
    end
  end
end

include Taxonomist

Sequel.extension :migration
Sequel::Migrator.run(DB, "db/migrations")
