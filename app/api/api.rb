require "grape"
require "rforce"

class UsefulStuff::Api < Grape::API
  prefix "api"
  version "v1"

  helpers do
    include UsefulStuff::Helpers
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

  resource :accounts do
    get "/search/:name.json", "/search/:name" do
      check_if_allowed(env)
      sfdc = new_salesforce_binding
      search = "find {#{params[:name]}} in name fields returning account(id, name, phone)"
      puts "search => #{search.inspect}"
      answer = sfdc.search(:searchString => search)
      result = answer.searchResponse.result
      error!("Account #{params[:name]} not found", 404) if result.nil?
      result.searchRecords.record
    end

    post do
      check_if_allowed(env)
      sfdc = new_salesforce_binding
      account = [
        :type,        "Account",
        :name,        params[:name],
        :phone,       params[:phone],
        :description, params[:description]
      ]
      answer = sfdc.create(:sObject => account)
      result = answer.createResponse
      if result.present?
        answer.createResponse.result
      else
        error!(answer.Fault.faultstring, 406)
      end
    end
  end
end
