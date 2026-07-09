module V1
  module User
    class CheckStatusController < ApplicationController
      def create
        response = CheckStatus::Handler.new(request: request).call
        render json: response.json, status: response.status
      end
    end
  end
end
