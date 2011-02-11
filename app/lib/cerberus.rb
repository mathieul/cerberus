require 'redis/lock'

module Cerberus
  extend self

  Error                 = Class.new(Exception)
  ReleaseLockImpossible = Class.new(Error)

  attr_reader :redis, :max_concurrent_access

  KEY_NAME_FREE_LOCKS = "global:list:freelocks"
  KEY_NAME_NUM_LOCKS = "global:value:numlocks"
  KEY_NAME_NEXT_SEQUENCE = "global:value:next_sequence"
  KEY_NAME_USER_ID_SEQUENCE = "global:value:user_id_sequence"
  KEY_NAME_USER_IDS_BY_NAME = "global:hash:user_ids_by_name"
  KEY_NAME_USER_IDS = "global:list:user_ids"
  KEY_NAME_USER_INFO_PREFIX = "user:hash:user_info_"
  KEY_NAME_USER_REQUESTS_PREFIX = "user:value:"
  KEY_NAME_USER_REQUESTS_SUFFIX = ":request:"

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

  def set_user(name, info)
    id = @redis.incr(KEY_NAME_USER_ID_SEQUENCE)
    @redis.multi
    @redis.lpush(KEY_NAME_USER_IDS, id)
    @redis.hset(KEY_NAME_USER_IDS_BY_NAME, name, id)
    info_id = "#{KEY_NAME_USER_INFO_PREFIX}#{id}"
    @redis.hmset(info_id, *info.to_a.flatten)
    @redis.exec
    id
  end

  def get_user(name)
    id = @redis.hget(KEY_NAME_USER_IDS_BY_NAME, name).to_i
    get_user_info(id)
  end

  def update_user(name, field, value)
    id = @redis.hget(KEY_NAME_USER_IDS_BY_NAME, name).to_i
    raise RuntimeError.new("User not found") if id == 0
    info_id = "#{KEY_NAME_USER_INFO_PREFIX}#{id}"
    @redis.hset(info_id, field, value)
  end

  def user_latest_requests(user_id, type = :id)
    key_name = latest_request_ids_key_name(user_id)
    mask = latest_request_ids_key_name(user_id, '')
    re = Regexp.new("^#{mask}(.*)$")
    keys = @redis.keys(key_name)
    return keys if type == :key
    keys.map do |name|
      match = re.match(name)
      match && match[1]
    end
  end

  def user_latest_request_times(user_id)
    keys = user_latest_requests(user_id, :key)
    keys.map do |key_name|
      @redis.get(key_name)
    end
  end

  def add_user_request_id(user_id, request_id)
    key_name = latest_request_ids_key_name(user_id, request_id)
    @redis.set(key_name, Time.now.to_s)
    @redis.expire(key_name, 60)
  end

  def user_num_requests_last_minute(user_id)
    key_name = latest_request_ids_key_name(user_id)
    @redis.keys(key_name).length
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

  def get_user_info(id)
    info_id = "#{KEY_NAME_USER_INFO_PREFIX}#{id}"
    info = @redis.hgetall(info_id)
    return nil if info.empty?
    info.symbolize_keys
  end

  def setup_for_user(id)
    info = get_user_info(id)
    return false if info.nil?
  end

  def latest_request_ids_key_name(user_id, request_id = "*")
    "#{KEY_NAME_USER_REQUESTS_PREFIX}#{user_id}#{KEY_NAME_USER_REQUESTS_SUFFIX}#{request_id}"
  end
end
