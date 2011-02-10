require "spec_helper"

describe Cerberus do
  before(:each) do
    UsefulStuff.setup
    Cerberus.redis.flushdb
  end

  describe "configuration" do
    it "initializes the connection with Redis with #setup" do
      Cerberus.setup
      Cerberus.redis.client.should be_connected
    end

    it "initializes $redis for integration with redis-objects with #setup" do
      Cerberus.setup
      $redis.should == Cerberus.redis
    end

    it "sets the number of concurent requests with #max_concurrent_access=" do
      Cerberus.max_concurrent_access = 3
      Cerberus.max_concurrent_access.should == 3
    end
  end

  describe "limit number of concurrent accesses" do
    it "can take a lock if there is at least one available" do
      Cerberus.max_concurrent_access = 3
      Cerberus.take_lock.should == "LOCK#001"
      Cerberus.take_lock.should == "LOCK#002"
      Cerberus.take_lock.should == "LOCK#003"
    end
  end
end
