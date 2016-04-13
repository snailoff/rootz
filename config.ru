## This is not needed for Thin > 1.0.0
require 'sass/plugin/rack'
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

ENV['RACK_ENV'] = "production"
require File.expand_path '../serve.rb', __FILE__

run Sinatra::Application
