#####################
# About
# This file is responsible for running the geminabox server.
# By default, the server will run on port 9292.

#####################
# Code
require 'rubygems'
require 'geminabox'

# The location to store the gems locally. Currently setup to store them in your
# /root/geminabox/data folder, but you can change this location to anywhere.
Geminabox.data = "./data"

# Remove this block if you don't want to add basic auth
use Rack::Auth::Basic, 'GemInAbox' do |username, password|
  # Add as many username/passwords as you want here.
  username == 'some_username' && password == 'a_password'
end

# Starts the gemserver
run Geminabox::Server
