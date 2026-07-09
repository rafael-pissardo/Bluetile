# db/seeds.rb
REDIS.sadd(Checks::CountryWhitelistCheck::WHITELIST_KEY, %w[US CA GB]) if REDIS.scard(Checks::CountryWhitelistCheck::WHITELIST_KEY).zero?
