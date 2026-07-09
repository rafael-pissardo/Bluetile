class RedisGateway
  REDIS_COMMAND_ERRORS = [
    Redis::BaseConnectionError,
    Redis::CannotConnectError,
    Redis::TimeoutError
  ].freeze

  def initialize(redis = nil)
    @redis = redis || Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  end

  def sismember(key, member)
    with_connection { @redis.sismember(key, member) }
  end

  def get(key)
    with_connection { @redis.get(key) }
  end

  def setex(key, ttl, value)
    with_connection { @redis.setex(key, ttl, value) }
  end

  def sadd(key, *members)
    with_connection { @redis.sadd(key, *members) }
  end

  def scard(key)
    with_connection { @redis.scard(key) }
  end

  def del(*keys)
    with_connection { @redis.del(*keys) }
  end

  def flushdb
    with_connection { @redis.flushdb }
  end

  def ping
    with_connection { @redis.ping }
  end

  private

  def with_connection
    yield
  rescue *REDIS_COMMAND_ERRORS => e
    raise Infrastructure::RedisUnavailableError, e.message
  end
end
