class ApplicationController < ActionController::API
  include ApiAuthenticatable

  rescue_from Infrastructure::RedisUnavailableError do |exception|
    Rails.logger.error("[RedisUnavailable] #{exception.message}")
    render json: { error: "Internal Server Error" }, status: :internal_server_error
  end
end
