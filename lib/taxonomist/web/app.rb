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
          if r.session[:twitter_id]
            r.redirect "app"
          else
            view "index"
          end
        end

        r.get "app" do
          "Hello world!"
        end
      end
    end
  end
end
