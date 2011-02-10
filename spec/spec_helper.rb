$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.expand_path("../../app", __FILE__)

require "rubygems"
require "bundler"

Bundler.setup :default, :test
ENV['RACK_ENV'] ||= "test"

require "ap"
require "useful_stuff"

RSpec.configure do |config|
  config.before(:all)  { UsefulStuff.setup }
  #config.before(:each) { UsefulStuff.redis.flushdb }
end
