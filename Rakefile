require 'logger'
require 'rake/clean'
require 'rake/testtask'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'taxonomist'

include Taxonomist

task default: %i[ test elm ]

desc "Build Elm JS"
task elm: FileList["lib/taxonomist/web/elm/*.elm"] do
  cd "lib/taxonomist/web/elm" do
    sh "elm-make Taxonomist.elm --output ../public/js/elm-taxonomist.js"
  end
end
CLOBBER.include("lib/taxonomist/web/public/Taxonomist.elm")

# web = "lib/taxonomist/web"
# FileList[File.join(web, "elm/Taxonomist.elm")].each do |elm|
#   rel = elm.pathmap("public/js/elm-%{.*,*}n.js", &:downcase)
#   pub = File.join(web, rel)
#   CLOBBER.include(pub)
#   file pub => elm do
#     cd elm.pathmap("%d") do
#       sh "elm-make #{elm.pathmap("%f")} --output #{File.join("..", rel)}"
#     end
#   end

#   desc "Build Elm JS"
#   task elm: pub
# end

desc 'Open an interactive console'
task :console, :user_id do |t, args|
  user_id = args[:user_id]

  DB.loggers << Logger.new($stdout)

  class QueJob < Sequel::Model; end

  twitter = Twitter::Client::Authed.new(
    api_key: ENV.fetch('TWITTER_API_KEY'),
    api_secret: ENV.fetch('TWITTER_API_SECRET'),
    access_token: ENV.fetch('TWITTER_ACCESS_TOKEN'),
    access_token_secret: ENV.fetch('TWITTER_ACCESS_TOKEN_SECRET'),
  )

  user = Models::User[user_id] if user_id

  require 'pry'
  binding.pry
end

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |t, args|
    require_relative 'config/que'
    Que.logger = Logger.new(STDOUT)
    Que.migrate!

    Sequel.extension :migration

    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(DB, 'db/migrations')
    end

    DB.extension :schema_dumper
    File.write('db/schema.rb',
               DB.dump_schema_migration(same_db: true).gsub(/^\s+$/, ''))
  end
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
  t.warning = false
  # t.verbose = true
end
