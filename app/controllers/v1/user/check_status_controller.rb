module V1
  module User
    class CheckStatusController < ApplicationController
      def create
        return render json: { error: "Bad Request" }, status: :bad_request unless json_request?

        parsed = parse_json_body
        return if performed?

        validation = CheckStatusParams.from_params(parsed)
        unless validation.valid?
          return render_validation_errors(validation)
        end

        ban_status = CheckStatusOrchestrator.new.call(
          CheckStatusOrchestrator::RequestContext.new(
            idfa: validation.idfa,
            rooted_device: validation.rooted_device,
            country: request.headers["CF-IPCountry"],
            ip: request.remote_ip
          )
        )

        render json: { ban_status: ban_status }, status: :ok
      end

      private

      def json_request?
        request.content_type&.include?("application/json")
      end

      def parse_json_body
        JSON.parse(request.raw_post).with_indifferent_access
      rescue JSON::ParserError
        render json: { error: "Bad Request" }, status: :bad_request
        nil
      end

      def render_validation_errors(validation)
        if validation.errors.intersect?(%i[missing_idfa missing_rooted_device])
          render json: { error: "Bad Request" }, status: :bad_request
        else
          render json: { error: "Unprocessable Entity" }, status: :unprocessable_entity
        end
      end
    end
  end
end
