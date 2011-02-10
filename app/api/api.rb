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
    get "/" do
      {:data_source => {:name => "whatever", :blah => "yes"}}
    end
  end
end
