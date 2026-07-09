require "rails_helper"

RSpec.describe Checks::CountryWhitelistCheck do
  subject(:check) { described_class.new(redis: redis) }

  let(:redis) { instance_double(RedisGateway) }

  it "passes when country is whitelisted" do
    allow(redis).to receive(:sismember).with("country_whitelist", "US").and_return(true)

    result = check.call(country: "US")

    expect(result.passed).to be(true)
  end

  it "fails when country is not whitelisted" do
    allow(redis).to receive(:sismember).with("country_whitelist", "XX").and_return(false)

    result = check.call(country: "XX")

    expect(result.banned?).to be(true)
  end

  it "fails when country is blank" do
    result = check.call(country: nil)

    expect(result.banned?).to be(true)
  end
end
