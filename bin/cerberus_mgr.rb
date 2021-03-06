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

  desc "basic_auth USER PASSWORD", "Get the encoded basic authentication string for the user and password."
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

  desc "set_user USER", "Set user permissions."
  def set_user(name)
    UsefulStuff.setup
    say "Let's create a new user [#{name}]", :red
    token = ask "What token should he use to access the API?"
    per_minute = ask "How many requests should we accept per minute?"
    say "Thanks."
    id = Cerberus.set_user(name, :token => token, :per_minute => per_minute.to_i,
                                 :id => id, :name => name)
    say "I created a new user:"
    say "  - name: #{name}", :blue
    say "  - id: #{id}", :blue
    say "  - token: #{token}", :blue
    say "  - per_minute: #{per_minute}", :blue
  end

  desc "show_user USER", "Show informations about user."
  def show_user(name)
    UsefulStuff.setup
    info = Cerberus.get_user(name)
    if info.nil?
      say "Sorry, couldn't find user [#{name}]", :red
    else
      say "Information about user [#{name}]:", :blue
      info[:num_requests_last_minute] = Cerberus.user_num_requests_last_minute(info[:id])
      ap info
      list = Cerberus.user_latest_request_times(info[:id])
      say "latest request times:", :green
      ap list.sort
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

