class Rack::Attack
  RATE_LIMIT = ENV.fetch("RATE_LIMIT_PER_MINUTE", "60").to_i

  throttle("check_status/ip", limit: RATE_LIMIT, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/v1/user/check_status"
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Too Many Requests" }.to_json ]
    ]
  end
end

Rack::Attack.enabled = !Rails.env.test? || ENV["RACK_ATTACK_ENABLED"] == "true"

if Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
end
