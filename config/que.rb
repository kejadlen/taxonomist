$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "taxonomist"

require "que"
Que.connection = Taxonomist::DB

$stdout.sync = true if Gem::Version.new(Que::Version) <= Gem::Version.new("0.11.2")
