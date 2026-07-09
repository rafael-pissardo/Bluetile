module Checks
  class VpnApiCheck
    CACHE_PREFIX = "vpnapi:ip:"
    CACHE_TTL = ENV.fetch("VPNAPI_CACHE_TTL", "86400").to_i

    def initialize(redis: REDIS, client: VpnApiClient.new)
      @redis = redis
      @client = client
    end

    def call(ip:)
      payload = fetch_payload(ip)
      security = payload.fetch("security", {})
      vpn = security["vpn"] == true
      tor = security["tor"] == true
      proxy = security["proxy"] == true

      Result.new(
        passed: !(vpn || tor),
        metadata: { proxy: proxy, vpn: vpn, tor: tor }
      )
    rescue VpnApiClient::Error, Faraday::Error, JSON::ParserError => e
      Rails.logger.warn("[VpnApiCheck] fail-open for ip=#{ip}: #{e.class} #{e.message}")
      Result.new(passed: true, metadata: { proxy: nil, vpn: nil, tor: nil })
    end

    private

    def fetch_payload(ip)
      cache_key = "#{CACHE_PREFIX}#{ip}"
      cached = @redis.get(cache_key)
      return JSON.parse(cached) if cached

      payload = @client.lookup(ip)
      @redis.setex(cache_key, CACHE_TTL, payload.to_json)
      payload
    end
  end
end
