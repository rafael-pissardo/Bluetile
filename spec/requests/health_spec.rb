require "rails_helper"

RSpec.describe "Health endpoints", type: :request do
  describe "GET /health" do
    it "returns ok without authentication" do
      get "/health"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("ok")
    end
  end

  describe "GET /health/deep" do
    it "returns component checks without authentication" do
      get "/health/deep"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["checks"]).to include("postgres" => true, "redis" => true)
    end
  end
end
