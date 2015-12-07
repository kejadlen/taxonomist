require "dotenv"
Dotenv.load

require "roda"
require "tilt/erb"

require_relative "../../taxonomist"

module Taxonomist
  module Web
    class App < Roda
      use Rack::Session::Cookie, secret: ENV["RODA_SECRET"]

      opts[:root] = File.expand_path("..", __FILE__)

      plugin :render, views: "views"

      plugin :multi_route
      require_relative "routes/auth"

      route do |r|
        r.multi_route

        r.root do
          if r.session[:user_id]
            r.redirect "filters"
          else
            view "index"
          end
        end

        r.get "filters" do
          "Hello world!"
        end
      end
    end
  end
end
