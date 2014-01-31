require_relative 'test_helper'

require 'dotenv'

require 'twister'

Dotenv.load(File.expand_path('../../test.env', __FILE__))

user = Twister::User.create()
