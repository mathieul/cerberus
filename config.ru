$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.expand_path("../app", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup

require "useful_stuff"
UsefulStuff.setup

run UsefulStuff::Api
