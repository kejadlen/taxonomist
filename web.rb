require 'dotenv'
Dotenv.load

require 'sinatra'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'twister'

get '/' do
  erb :index
end
