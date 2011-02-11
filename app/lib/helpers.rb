module UsefulStuff
  module Helpers
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

    def new_salesforce_binding
      binding = RForce::Binding.new("https://www.salesforce.com/services/Soap/u/20.0")
      binding.login "mlajugie@liveops.com", "matrix00Q6iJNw8e8h1fQ2txUupdiKek"
      binding
    end
  end
end

