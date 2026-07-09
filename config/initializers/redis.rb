Rails.application.config.after_initialize do
  ::REDIS = RedisGateway.new unless defined?(::REDIS)
end
