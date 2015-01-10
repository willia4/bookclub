#require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'sinatra/content_for2'
require 'rack/throttle'
require 'yaml'

# require 'sass/plugin/rack'
# use Sass::Plugin::Rack

# Sass::Plugin.options[:cache] = false
# Sass::Plugin.options[:always_update] = true

# load config into global variable
raise "Missing secrets.yaml file. This file is not tracked in source control and must be created." if not File.file?('./secrets.yaml')
$config = YAML::load(File.open("secrets.yaml"))

use Rack::Throttle::Hourly, :max => 3000
# helpers Sinatra::ContentFor2

require './routes/app.rb'

run Sinatra::Application
