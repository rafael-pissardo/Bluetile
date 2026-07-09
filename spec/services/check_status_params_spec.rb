require "rails_helper"

RSpec.describe CheckStatusParams do
  it "accepts valid params" do
    result = described_class.from_params(idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6", rooted_device: false)

    expect(result).to be_valid
  end

  it "rejects invalid uuid" do
    result = described_class.from_params(idfa: "bad", rooted_device: false)

    expect(result.errors).to include(:invalid_idfa)
  end

  it "rejects non-boolean rooted_device" do
    result = described_class.from_params(idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6", rooted_device: "yes")

    expect(result.errors).to include(:invalid_rooted_device)
  end
end
