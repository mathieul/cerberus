require 'redis/lock'

module Cerberus
  extend self
  attr_reader :redis, :max_concurrent_access

  KEY_NAME_FREE_LOCKS = "global:list:freelocks"
  KEY_NAME_USED_LOCKS = "global:list:usedlocks"

  def setup(c = {})
    return @redis if @redis.present?
    @redis = Redis.new(:host         => c.redis_host,
                       :port         => c.redis_port,
                       :thread_safe  => c.thread_safe)
    @redis.select(c.redis_db || 0)
    $redis = @redis
    @redis
  end

  def max_concurrent_access=(value)
    @redis.multi
    @redis.del(KEY_NAME_FREE_LOCKS)
    @redis.del(KEY_NAME_USED_LOCKS)
    value.times { |i| @redis.lpush(KEY_NAME_FREE_LOCKS, lock_name(i)) }
    @redis.exec
    @max_concurrent_access = value
  end

  def take_lock
    lock = nil
    glock.lock do
      key_name, lock = @redis.brpop(KEY_NAME_FREE_LOCKS, 1)
      @redis.lpush(KEY_NAME_USED_LOCKS, lock)
    end
    lock
  end

  def release_lock(lock)
    glock.lock do
      @redis.lrem(KEY_NAME_USED_LOCKS, 1, lock)
      @redis.lpush(KEY_NAME_FREE_LOCKS, lock)
    end
    true
  end

  def lock_status
    {}.tap do |status|
      glock.lock do
        status[:free] = @redis.llen(KEY_NAME_FREE_LOCKS)
        status[:used] = @redis.llen(KEY_NAME_USED_LOCKS)
      end
    end
  end

  private

  def lock_name(i)
    index = "%03d" % (i + 1)
    "LOCK##{index}"
  end

  def glock
    @glock ||= Redis::Lock.new('cerberus_lock', :expiration => 0, :timeout => 0.1)
  end
end
