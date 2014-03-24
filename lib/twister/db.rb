require 'logger'

require 'sequel'

module Twister
  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
  DB.extension :pg_array
  # DB.loggers << Logger.new(STDOUT)
end
