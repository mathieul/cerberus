$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.expand_path("../app", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup :default, :runtime

require "useful_stuff"
UsefulStuff.setup
Cerberus.max_concurrent_access = 2

run UsefulStuff::Api
