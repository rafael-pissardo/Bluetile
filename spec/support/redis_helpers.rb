module RedisHelpers
  def seed_country_whitelist(*countries)
    REDIS.del(Checks::CountryWhitelistCheck::WHITELIST_KEY)
    REDIS.sadd(Checks::CountryWhitelistCheck::WHITELIST_KEY, countries) if countries.any?
  end

  def flush_redis!
    REDIS.flushdb
  end
end

RSpec.configure do |config|
  config.include RedisHelpers

  config.before do
    flush_redis!
    seed_country_whitelist("US", "CA")
  end
end
