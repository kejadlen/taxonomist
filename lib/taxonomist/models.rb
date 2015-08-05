require "virtus"

module Taxonomist
  module Models
    class User
      include Virtus.model

      attribute :screen_name, String
    end
  end
end
