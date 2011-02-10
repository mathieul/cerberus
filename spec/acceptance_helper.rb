require File.expand_path("../spec_helper", __FILE__)
require "steak"
require 'rack/test'

require 'base64'
def encode_basic(agent_id, password)
  "Basic " + Base64.encode64("#{agent_id}:#{password}")
end

module BasicAuthHelpers
  def set_auth(user, token)
    @auth_user, @auth_token = user, token
  end

  %w(get post put delete).each do |name|
    define_method(:"auth_#{name}") do |url, params = {}|
      auth_method(name.to_sym, url, params)
    end
  end

  def last_response_from_json
    JSON.parse(last_response.body)
  end

  private

  def auth_method(meth, url, params = {})
    send(meth, url, params, 'HTTP_AUTHORIZATION' => encode_basic(@auth_user, @auth_token))
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods, :type => :acceptance
  config.include BasicAuthHelpers,    :type => :acceptance
end
