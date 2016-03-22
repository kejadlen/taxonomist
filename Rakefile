require "logger"

$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
require "taxonomist"
include Taxonomist

desc "Open an interactive console"
task :console, :user_id do |t, args|
  user_id = args[:user_id]

  require "logger"
  DB.loggers << Logger.new($stdout)

  class QueJob < Sequel::Model; end

  api_key = ENV.fetch("TWITTER_API_KEY")
  api_secret = ENV.fetch("TWITTER_API_SECRET")
  access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
  access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")

  twitter = Twitter::Authed.new(api_key: api_key,
                                api_secret: api_secret,
                                access_token: access_token,
                                access_token_secret: access_token_secret)

  user = Models::User[user_id] if user_id

  require "pry"
  binding.pry
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require_relative "config/que"
    Que.logger = Logger.new(STDOUT)
    Que.migrate!

    Sequel.extension :migration

    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB, "db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(DB, "db/migrations")
    end

    DB.extension :schema_dumper
    File.write("db/schema.rb", DB.dump_schema_migration(same_db: true).gsub(/^\s+$/, ''))
  end
end

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/test_*.rb"]
  t.warning = false
  # t.verbose = true
end

task default: :test
