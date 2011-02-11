require "grape"

class UsefulStuff::Api < Grape::API
  prefix "api"
  version "v1"

  helpers do
  end

  http_basic do |user_id, token|
    true
  end

  resource :data_sources do
    get do
      begin
        lock = Cerberus.take_lock
        error!("Server busy, please try again later", 405) if lock.nil?
        puts "LOCKED"
        #unless rand(3) == 0
        if true
          sleep_time = rand(20).to_f / 10
          puts "OK: sleep #{sleep_time}"
          sleep sleep_time
          {:data_source => {:name => "whatever", :blah => "yes"}}
        else
          puts "NOK"
          sleep 3
          error!("Request timed out after 3 seconds", 408)
        end
      ensure
        Cerberus.release_lock(lock) unless lock.nil?
        puts "UNLOCKED" unless lock.nil?
      end
    end
  end
end
