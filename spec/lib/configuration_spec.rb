require "spec_helper"

describe UsefulStuff do
  describe "application configuration" do
    it "raises an error of no block is given" do
      lambda { UsefulStuff.configure }.should raise_error(ArgumentError)
    end

    it "raises an error when a config attribute doesn't exist" do
      lambda {
        UsefulStuff.configuration.does_not_exist
      }.should raise_error(UsefulStuff::AttributeNotSupported)
    end

    it "can configure redis host with #redis_host" do
      UsefulStuff.configure { |config| config.redis_host = "my_host" }
      UsefulStuff.configuration.redis_host.should == "my_host"
    end

    it "can configure redis port with #redis_port" do
      UsefulStuff.configure { |config| config.redis_port = 6379 }
      UsefulStuff.configuration.redis_port.should == 6379
    end

    it "can configure redis db (0, 1, 2, ..., 8) with #redis_db" do
      UsefulStuff.configure { |config| config.redis_db = 1 }
      UsefulStuff.configuration.redis_db.should == 1
    end

    it "can configure redis to use as thread-safe with #thread_safe" do
      UsefulStuff.configure { |config| config.thread_safe = true }
      UsefulStuff.configuration.thread_safe.should be_true
    end

    it "can configure all attributes at once using #from_hash" do
      UsefulStuff.configure do |config|
        config.from_hash(:redis_host => "serge",
                         :redis_port => 6380,
                         :redis_db   => 2)
      end
      UsefulStuff.configuration.redis_host.should == "serge"
      UsefulStuff.configuration.redis_port.should == 6380
      UsefulStuff.configuration.redis_db.should == 2
      UsefulStuff.configuration.thread_safe.should be_false
    end
  end

  describe "Redis connection" do
    it "connects to Redis with #setup" do
      UsefulStuff.setup
      UsefulStuff.redis.client.should be_connected
    end
  end
end
