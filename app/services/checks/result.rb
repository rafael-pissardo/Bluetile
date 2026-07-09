module Checks
  class Result
    attr_reader :passed, :metadata

    def initialize(passed:, metadata: {})
      @passed = passed
      @metadata = metadata
    end

    def banned?
      !passed
    end
  end
end
