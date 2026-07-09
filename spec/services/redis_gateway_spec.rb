require "rails_helper"

RSpec.describe RedisGateway do
  let(:redis) { instance_double(Redis) }
  let(:gateway) { described_class.new(redis) }

  it "raises RedisUnavailableError when redis is down" do
    allow(redis).to receive(:ping).and_raise(Redis::CannotConnectError)

    expect { gateway.ping }.to raise_error(Infrastructure::RedisUnavailableError)
  end
end
