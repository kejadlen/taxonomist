require "sequel"
db = Sequel.connect(ENV.fetch("DATABASE_URL"))

require "que"
Que.connection = db

$stdout.sync = true if Gem::Version.new(Que::Version) <= Gem::Version.new("0.11.2")

require_relative "../lib/taxonomist"
