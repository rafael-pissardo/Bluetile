RSpec.configure do |config|
  config.before do
    ENV["API_KEY"] = "test-api-key"
    ENV["VPNAPI_KEY"] = "test-key"
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end
end
