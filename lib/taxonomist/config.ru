require "roda"
require "tilt/erb"

module Taxonomist
  class Web < Roda
    opts[:root] = File.expand_path("../web", __FILE__)

    plugin :render, views: "views"

    route do |r|
      r.root do
        view("index")
      end
    end
  end
end

run Taxonomist::Web.freeze.app
