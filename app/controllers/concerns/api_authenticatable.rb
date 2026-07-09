module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api!
  end

  private

  def authenticate_api!
    return if skip_api_authentication?

    provided = request.headers["X-API-Key"].to_s
    expected = ENV.fetch("API_KEY", "")

    if expected.blank? || provided.blank? ||
       !ActiveSupport::SecurityUtils.secure_compare(provided, expected)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def skip_api_authentication?
    false
  end
end
