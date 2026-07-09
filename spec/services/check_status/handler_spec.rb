require "rails_helper"

RSpec.describe CheckStatus::Handler do
  let(:request) do
    instance_double(
      ActionDispatch::Request,
      content_type: "application/json",
      raw_post: { idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6", rooted_device: false }.to_json,
      remote_ip: "127.0.0.1"
    ).tap do |req|
      allow(req).to receive(:headers).and_return({ "CF-IPCountry" => "US" })
    end
  end
  let(:orchestrator) { instance_double(CheckStatusOrchestrator, call: "not_banned") }

  it "returns ok response with ban_status" do
    response = described_class.new(request: request, orchestrator: orchestrator).call

    expect(response.status).to eq(:ok)
    expect(response.json).to eq(ban_status: "not_banned")
  end

  it "returns bad request for invalid content type" do
    allow(request).to receive(:content_type).and_return("text/plain")

    response = described_class.new(request: request, orchestrator: orchestrator).call

    expect(response.status).to eq(:bad_request)
  end
end
