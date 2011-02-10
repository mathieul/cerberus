#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path("../../app", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup :default, :development

require "thor"
require "thor/actions"
require 'base64'
require "useful_stuff"
require "awesome_print"

class CerberusMgr < Thor
  include Thor::Actions

  add_runtime_options!
  check_unknown_options!

  desc "basic_auth USER PASSWORD", "Get the encoded basic authentication string for the user and password"
  def basic_auth(user, password)
    puts "Header to add to your HTTP requests: "
    p encode_basic(user, password)
  end

  desc "set_max_concurrent_access NUM_LOCKS", "Set the maximum number of concurent access."
  def set_max_concurrent_access(num_locks)
    num_locks = num_locks.to_i
    UsefulStuff.setup
    Cerberus.max_concurrent_access = num_locks
    puts "Access now restricted to #{num_locks} concurrent access."
  end

  desc "lock_status [REFRESH_RATE]", "Show the number of free locks and used locks, and refresh if REFRESH_RATE (in secs) provided."
  def lock_status(refresh_rate = nil)
    UsefulStuff.setup
    loop do
      system("clear") unless refresh_rate.nil?
      ap Cerberus.lock_status
      break if refresh_rate.nil?
      sleep refresh_rate.to_f
    end
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

