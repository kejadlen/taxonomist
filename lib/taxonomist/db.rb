require "sequel"

Sequel::Model.plugin :timestamps

DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
DB.extension :pg_json
