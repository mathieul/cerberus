require "grape/middleware/base"

module Cerberus
  LocalError = Class.new(Error)
  class Middleware < Grape::Middleware::Base
    def before
      @req_id = Cerberus.next_sequence
      @lock = Cerberus.take_lock
      if @lock.nil?
        log("NO FREE LOCK")
        @error_result = error_response(:message => "Server busy, please try again later", :status => 405)
        raise LocalError
      end
      log("LOCKED #{@lock.inspect}")
    end

      def call!(env)
        @env = env
        before
        @app_response = @app.call(@env)
        after || @app_response
      rescue LocalError
        @error_result
      end

    def after
      unless @lock.nil?
        Cerberus.release_lock(@lock)
        log("UNLOCKED #{@lock.inspect}")
      end
      nil
    end

    private

    def log(msg)
      puts "[% 3d] %s" % [@req_id, msg]
    end

    def error_response(error = {})
      Rack::Response.new([(error[:message] || options[:default_message])], error[:status] || 403, error[:headers] || {}).finish
    end
  end
end
