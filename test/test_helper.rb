require "minitest"
require "pry"
require "sequel"

require "dotenv"
Dotenv.load(".test.envrc")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "taxonomist/db"

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
