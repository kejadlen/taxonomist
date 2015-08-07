require "sequel"

Sequel::Model.plugin :timestamps, update_on_create: true

module Taxonomist
  DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
  DB.extension :pg_array, :pg_json

  module Models
    class User < Sequel::Model
    end
  end
end
