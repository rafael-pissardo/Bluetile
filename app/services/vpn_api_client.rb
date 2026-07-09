class VpnApiClient
  class Error < StandardError; end

  def initialize(api_key: ENV.fetch("VPNAPI_KEY"))
    @api_key = api_key
    @connection = Faraday.new do |f|
      f.options.timeout = ENV.fetch("VPNAPI_TIMEOUT_MS", "5000").to_i / 1000.0
      f.options.open_timeout = 2
    end
  end

  def lookup(ip)
    response = @connection.get("https://vpnapi.io/api/#{ip}") do |req|
      req.params["key"] = @api_key
    end

    raise Error, "VPNAPI returned #{response.status}" unless response.success?

    JSON.parse(response.body)
  end
end
