require "acceptance_helper"
require "useful_stuff"

feature "Throttle API access" do
  def app; UsefulStuff::Api end

  background do
    set_auth "user", "token"
  end

  scenario "scaffold, replace me :D" do
    auth_get "/api/v1/data_sources"
    last_response.status.should == 200
    last_response_from_json.should == {"data_source" => {"name" => "whatever", "blah" => "yes"}}
  end
end
