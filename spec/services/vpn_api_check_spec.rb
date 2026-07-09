require "rails_helper"

RSpec.describe Checks::VpnApiCheck do
  let(:ip) { "203.0.113.10" }
  let(:redis) { REDIS }
  let(:client) { instance_double(VpnApiClient) }
  let(:check) { described_class.new(redis: redis, client: client) }

  before do
    redis.del("#{described_class::CACHE_PREFIX}#{ip}")
  end

  it "passes when VPNAPI returns an error (fail-open)" do
    allow(client).to receive(:lookup).with(ip).and_raise(VpnApiClient::Error, "VPNAPI returned 500")

    result = check.call(ip: ip)

    expect(result.passed).to be(true)
  end

  it "uses Redis cache on second call without HTTP request" do
    payload = {
      "ip" => ip,
      "security" => { "vpn" => false, "tor" => false, "proxy" => false }
    }

    expect(client).to receive(:lookup).with(ip).once.and_return(payload)

    check.call(ip: ip)
    check.call(ip: ip)
  end
end
