require "grape"

class UsefulStuff::Api < Grape::API
  prefix "api"
  version "v1"

  helpers do
    def log(msg)
      puts "[% 3d] #{msg}" % env["X_Request_Id"].to_i
    end

    def check_if_allowed(env)
      info = user_info(env)
      if new_request_allowed?(info)
        new_request(info[:id], env["X_Request_Id"]) if info.present?
      else
        error!("You exceeded your maximum amount, try again in 1 minute", 403)
      end
    end

    def user_info(env)
      result = Rack::Auth::Basic::Request.new(env)
      return nil unless result.provided?
      name, pwd = result.credentials
      Cerberus.get_user(name)
    end

    def new_request_allowed?(info)
      num_requests = Cerberus.user_num_requests_last_minute(info[:id])
      num_requests < info[:per_minute].to_i
    end

    def new_request(user_id, request_id)
      Cerberus.add_user_request_id(user_id, request_id)
    end
  end

  http_basic do |user_name, token|
    info = Cerberus.get_user(user_name)
    if info.present? && info[:token] == token
      true
    else
      false
    end
  end

  resource :fakes do
    get do
      check_if_allowed(env)
      sleep_time = rand(20).to_f / 10
      log "Fake processing will take #{sleep_time} s"
      sleep sleep_time
      [{:fake => {:name => "whatever", :blah => "yes", :processing => sleep_time}}]
    end
  end
end
