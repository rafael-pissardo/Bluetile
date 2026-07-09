class HealthController < ApplicationController
  skip_before_action :authenticate_api!

  def show
    render json: {
      status: "ok",
      timestamp: Time.current.iso8601
    }, status: :ok
  end

  def deep
    checks = {
      postgres: postgres_ok?,
      redis: redis_ok?
    }
    healthy = checks.values.all?
    status = healthy ? :ok : :service_unavailable

    render json: {
      status: healthy ? "healthy" : "degraded",
      checks: checks,
      timestamp: Time.current.iso8601
    }, status: status
  end

  private

  def postgres_ok?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def redis_ok?
    REDIS.ping == "PONG"
  rescue Infrastructure::RedisUnavailableError
    false
  end
end
