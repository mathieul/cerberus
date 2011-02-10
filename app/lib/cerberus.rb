module Cerberus
  extend self
  attr_reader :redis, :max_concurrent_access

  KEY_NAME_AVAILABLE_LOCKS = "global:list:freelocks"
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
    @redis.del(KEY_NAME_AVAILABLE_LOCKS)
    @redis.del(KEY_NAME_USED_LOCKS)
    value.times { |i| @redis.lpush(KEY_NAME_AVAILABLE_LOCKS, lock_name(i)) }
    @redis.exec
    @max_concurrent_access = value
  end

  def take_lock
    key_name, lock = @redis.brpop(KEY_NAME_AVAILABLE_LOCKS, 1)
    @redis.lpush(KEY_NAME_USED_LOCKS, lock)
    lock
  end

  private

  def lock_name(i)
    index = "%03d" % (i + 1)
    "LOCK##{index}"
  end
end
