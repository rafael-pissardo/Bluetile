module Checks
  class CountryWhitelistCheck
    WHITELIST_KEY = "country_whitelist"

    def initialize(redis: REDIS)
      @redis = redis
    end

    def call(country:)
      return Result.new(passed: false, metadata: { country: country }) if country.blank?

      whitelisted = @redis.sismember(WHITELIST_KEY, country.upcase)
      Result.new(passed: whitelisted, metadata: { country: country })
    end
  end
end
