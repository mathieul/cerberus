require "grape"



class UsefulStuff::Api < Grape::API
  prefix "api"
  version "v1"

  http_basic do |user_name, token|
    info = Cerberus.get_user(user_name)
    info.present? && info[:token] == token
  end

  resource :fakes do
    get do
      begin
        sleep_time = rand(20).to_f / 10
        #log(req_id, "Fake processing will take #{sleep_time} s")
        sleep sleep_time
        [{:fake => {:name => "whatever", :blah => "yes", :processing => sleep_time}}]
      end
    end
  end
end
