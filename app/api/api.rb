require "grape"

class UsefulStuff::Api < Grape::API
  prefix "api"
  version "v1"

  helpers do
  end

  http_basic do |user_name, token|
    info = Cerberus.get_user(user_name)
    info.present? && info[:token] == token
  end

  resource :data_sources do
    get do
      req_id = Cerberus.next_sequence
      begin
        lock = Cerberus.take_lock
        if lock.nil?
          puts "[% 3d] NO FREE LOCK" % req_id
          error!("Server busy, please try again later", 405)
        end
        puts "[% 3d] LOCKED" % req_id
        sleep_time = rand(20).to_f / 10
        puts "[% 3d] will process for #{sleep_time} s"
        sleep sleep_time
        {:data_source => {:name => "whatever", :blah => "yes"}}
      ensure
        unless lock.nil?
          Cerberus.release_lock(lock)
          puts "[% 3d] UNLOCKED" % req_id
        end
      end
    end
  end
end
