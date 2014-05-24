require 'logger'

require 'sequel'
Sequel.default_timezone = :utc
Sequel::Model.plugin :timestamps

module Twister
  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
  DB.extension :pg_array

  # DB.loggers << Logger.new(STDOUT)
end
