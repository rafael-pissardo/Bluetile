require "rails_helper"

RSpec.describe CheckStatusOrchestrator do
  subject(:orchestrator) do
    described_class.new(
      country_check: country_check,
      rooted_check: rooted_check,
      vpn_check: vpn_check,
      logger: logger
    )
  end

  let(:country_check) { instance_double(Checks::CountryWhitelistCheck) }
  let(:rooted_check) { instance_double(Checks::RootedDeviceCheck) }
  let(:vpn_check) { instance_double(Checks::VpnApiCheck) }
  let(:logger) { instance_double(IntegrityLogger, log: true) }
  let(:context) do
    described_class::RequestContext.new(
      idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6",
      rooted_device: false,
      country: "US",
      ip: "127.0.0.1"
    )
  end

  before do
    allow(country_check).to receive(:call).and_return(
      Checks::Result.new(passed: true, metadata: { country: "US" })
    )
    allow(rooted_check).to receive(:call).and_return(
      Checks::Result.new(passed: true, metadata: {})
    )
    allow(vpn_check).to receive(:call).and_return(
      Checks::Result.new(passed: true, metadata: { proxy: false, vpn: false })
    )
  end

  it "returns banned immediately for already banned users" do
    create(:user, idfa: context.idfa, ban_status: :banned)
    allow(vpn_check).to receive(:call)

    expect(orchestrator.call(context)).to eq("banned")
    expect(vpn_check).not_to have_received(:call)
  end

  it "creates user and logs on first request" do
    expect(logger).to receive(:log).once

    expect {
      orchestrator.call(context)
    }.to change(User, :count).by(1)
  end
end
