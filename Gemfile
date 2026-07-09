source "https://rubygems.org"

ruby "3.4.9"

gem "rails", "8.1.3"
gem "pg", "1.6.3"
gem "puma", ">= 5.0"
gem "redis", "5.4.1"
gem "faraday", "2.14.3"
gem "rack-attack", "6.8.0"

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails", "8.0.4"
  gem "factory_bot_rails", "6.5.1"
  gem "webmock", "3.26.2"
  gem "simplecov", "0.22.0", require: false
end
