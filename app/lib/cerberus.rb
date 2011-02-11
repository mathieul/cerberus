require 'redis/lock'

module Cerberus
  extend self

  Error                 = Class.new(Exception)
  ReleaseLockImpossible = Class.new(Error)

  attr_reader :redis, :max_concurrent_access

  KEY_NAME_FREE_LOCKS = "global:list:freelocks"
  KEY_NAME_NUM_LOCKS = "global:value:numlocks"
  KEY_NAME_NEXT_SEQUENCE = "global:value:next_sequence"

  def setup(c = nil)
    return @redis if @redis.present?
    @redis = if c.nil?
      Redis.new
    else
      Redis.new(:host         => c.redis_host,
                :port         => c.redis_port,
                :thread_safe  => c.thread_safe)
    end
    cfg = c.instance_eval { @options }
    @redis.select(c.redis_db || 0)
    @redis.set(KEY_NAME_NEXT_SEQUENCE, 1)
    $redis = @redis
    @redis
  end

  def next_sequence
    @redis.incr(KEY_NAME_NEXT_SEQUENCE)
  end

  def max_concurrent_access=(value)
    @redis.multi
    @redis.set(KEY_NAME_NUM_LOCKS, value)
    @redis.del(KEY_NAME_FREE_LOCKS)
    value.times { |i| @redis.lpush(KEY_NAME_FREE_LOCKS, lock_name(i)) }
    @redis.exec
    @max_concurrent_access = value
  end

  def take_lock
    @redis.rpop(KEY_NAME_FREE_LOCKS)
  end

  def release_lock(lock)
    raise ReleaseLockImpossible.new("lock is invalid") if lock.blank?
    frees = @redis.lrange(KEY_NAME_FREE_LOCKS, 0, -1)
    raise ReleaseLockImpossible.new("lock #{lock} is not used") if frees.include?(lock)
    @redis.lpush(KEY_NAME_FREE_LOCKS, lock)
    true
  end

  def lock_status
    {}.tap do |status|
      glock.lock do
        number = @redis.get(KEY_NAME_NUM_LOCKS).to_i
        status[:free] = @redis.llen(KEY_NAME_FREE_LOCKS)
        status[:used] = number - status[:free]
      end
    end
  end

  private

  def lock_name(i)
    index = "%03d" % (i + 1)
    "LOCK##{index}"
  end

  def glock
    @glock ||= Redis::Lock.new('cerberus_lock', :expiration => 15, :timeout => 10)
  end
end
