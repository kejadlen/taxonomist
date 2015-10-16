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
    def without_warnings
      original_verbose, $VERBOSE = $VERBOSE, nil
      yield
      $VERBOSE = original_verbose
    end

    def with_const(namespace, const, value)
      original_value = namespace.const_get(const)
      without_warnings do
        namespace.const_set(const, value)
      end
      yield
    ensure
      without_warnings do
        namespace.const_set(const, original_value)
      end
    end

    module Foo; BAR = 1; end
    def test_replace_const
      assert_equal 1, Foo::BAR
      with_const(Foo, :BAR, 2) do
        assert_equal(2, Foo::BAR)
      end
      assert_equal 1, Foo::BAR
    end

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
