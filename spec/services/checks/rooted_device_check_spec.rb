require "rails_helper"

RSpec.describe Checks::RootedDeviceCheck do
  subject(:check) { described_class.new }

  it "passes when device is not rooted" do
    expect(check.call(rooted_device: false).passed).to be(true)
  end

  it "bans when device is rooted" do
    expect(check.call(rooted_device: true).banned?).to be(true)
  end
end
