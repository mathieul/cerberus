#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path("../../app", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup :default, :development

require "thor"
require "thor/actions"
require 'base64'
require "useful_stuff"

class CerberusMgr < Thor
  include Thor::Actions

  add_runtime_options!
  check_unknown_options!

  desc "basic_auth USER PASSWORD", "Get the encoded basic authentication string for the user and password"
  def basic_auth(user, password)
    puts "Header to add to your HTTP requests: "
    p encode_basic(user, password)
  end

  private

  def encode_basic(user, password)
    "Authorization: Basic " + Base64.encode64("#{user}:#{password}")
  end
end

require "rubygems" if RUBY_VERSION[0..2].to_f < 1.9

begin
  CerberusMgr.start
rescue Exception => ex
  STDERR.puts "#{File.basename(__FILE__)}: #{ex}"
  raise
end

