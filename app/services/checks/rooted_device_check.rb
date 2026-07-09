module Checks
  class RootedDeviceCheck
    def call(rooted_device:)
      Result.new(passed: !rooted_device, metadata: { rooted_device: rooted_device })
    end
  end
end
