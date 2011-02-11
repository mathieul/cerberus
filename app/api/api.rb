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
        #if rand(3) == 0
        if false
          {:data_source => {:name => "whatever", :blah => "yes"}}
        else
          sleep 5
          error!("Request timed out after 5 seconds", 408)
        end
      ensure
        Cerberus.release_lock(lock) unless lock.nil?
      end
    end
  end
end
