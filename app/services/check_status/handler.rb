module CheckStatus
  Response = Data.define(:status, :json)

  class Handler
    def initialize(request:, orchestrator: CheckStatusOrchestrator.new)
      @request = request
      @orchestrator = orchestrator
    end

    def call
      return Response.new(status: :bad_request, json: { error: "Bad Request" }) unless json_request?

      body = parse_json_body
      return body if body.is_a?(Response)

      validation = CheckStatusParams.from_params(body)
      return validation_response(validation) unless validation.valid?

      ban_status = @orchestrator.call(
        CheckStatusOrchestrator::RequestContext.new(
          idfa: validation.idfa,
          rooted_device: validation.rooted_device,
          country: @request.headers["CF-IPCountry"],
          ip: @request.remote_ip
        )
      )

      Response.new(status: :ok, json: { ban_status: ban_status })
    end

    private

    def json_request?
      @request.content_type&.include?("application/json")
    end

    def parse_json_body
      JSON.parse(@request.raw_post).with_indifferent_access
    rescue JSON::ParserError
      Response.new(status: :bad_request, json: { error: "Bad Request" })
    end

    def validation_response(validation)
      if validation.errors.intersect?(%i[missing_idfa missing_rooted_device])
        Response.new(status: :bad_request, json: { error: "Bad Request" })
      else
        Response.new(status: :unprocessable_content, json: { error: "Unprocessable Entity" })
      end
    end
  end
end
