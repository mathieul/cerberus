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
    it "can take a lock if there is at least one available with #take_lock" do
      Cerberus.max_concurrent_access = 3
      Cerberus.take_lock.should == "LOCK#001"
      Cerberus.take_lock.should == "LOCK#002"
      Cerberus.take_lock.should == "LOCK#003"
    end

    it "return nil if no lock is available within 1 sec with #take_lock" do
      Cerberus.max_concurrent_access = 1
      Cerberus.take_lock.should == "LOCK#001"
      Cerberus.take_lock.should be_nil
      Cerberus.redis.lrange(Cerberus::KEY_NAME_FREE_LOCKS, 0, -1).should be_empty
    end

    it "can return a used lock with #release_lock" do
      Cerberus.max_concurrent_access = 1
      Cerberus.take_lock.should == "LOCK#001"
      Cerberus.release_lock("LOCK#001").should be_true
      Cerberus.redis.lrange(Cerberus::KEY_NAME_FREE_LOCKS, 0, -1).should == ["LOCK#001"]
    end

    it "raises an error if returning a lock that's not currently used" do
      Cerberus.max_concurrent_access = 1
      Cerberus.take_lock.should == "LOCK#001"
      Cerberus.release_lock("LOCK#001")
      lambda {
        Cerberus.release_lock("LOCK#001")
      }.should raise_error(Cerberus::ReleaseLockImpossible)
    end

    it "raises an error if trying to release a blank lock" do
      lambda {
        Cerberus.release_lock(nil)
      }.should raise_error(Cerberus::ReleaseLockImpossible)
      lambda {
        Cerberus.release_lock("")
      }.should raise_error(Cerberus::ReleaseLockImpossible)
    end

    it "returns the number of available and used locks with #lock_status" do
      Cerberus.max_concurrent_access = 3
      Cerberus.lock_status.should == {:free => 3, :used => 0}
      Cerberus.take_lock.should == "LOCK#001"
      Cerberus.lock_status.should == {:free => 2, :used => 1}
      Cerberus.take_lock.should == "LOCK#002"
      Cerberus.take_lock.should == "LOCK#003"
      Cerberus.lock_status.should == {:free => 0, :used => 3}
      Cerberus.release_lock("LOCK#001")
      Cerberus.lock_status.should == {:free => 1, :used => 2}
    end
  end
end
