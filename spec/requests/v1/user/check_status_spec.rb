require "rails_helper"

RSpec.describe "POST /v1/user/check_status", type: :request do
  let(:idfa) { "8264148c-be95-4b2b-b260-6ee98dd53bf6" }
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "CF-IPCountry" => "US"
    }
  end

  def post_check_status(body, extra_headers = {})
    post "/v1/user/check_status", params: body.to_json, headers: headers.merge(extra_headers)
  end

  def stub_vpnapi(ip:, vpn: false, tor: false, proxy: false, status: 200)
    stub_request(:get, "https://vpnapi.io/api/#{ip}")
      .with(query: hash_including("key" => "test-key"))
      .to_return(
        status: status,
        body: {
          ip: ip,
          security: { vpn: vpn, tor: tor, proxy: proxy, relay: false }
        }.to_json
      )
  end

  before do
    stub_vpnapi(ip: "127.0.0.1")
  end

  describe "happy path" do
    it "returns not_banned and creates user and integrity log" do
      expect {
        post_check_status(idfa: idfa, rooted_device: false)
      }.to change(User, :count).by(1).and change(IntegrityLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("ban_status" => "not_banned")

      user = User.find_by!(idfa: idfa)
      expect(user.ban_status).to eq("not_banned")

      log = IntegrityLog.last
      expect(log.idfa).to eq(idfa)
      expect(log.ban_status).to eq("not_banned")
      expect(log.country).to eq("US")
      expect(log.rooted_device).to be(false)
      expect(log.ip).to be_present
      expect(log.created_at).to be_present
      expect(log.proxy).to be(false)
      expect(log.vpn).to be(false)
    end
  end

  describe "ban triggers" do
    it "bans when country is not whitelisted without calling VPNAPI" do
      post_check_status({ idfa: idfa, rooted_device: false }, "CF-IPCountry" => "XX")

      expect(response.parsed_body).to eq("ban_status" => "banned")
      expect(a_request(:get, %r{https://vpnapi.io/api/})).not_to have_been_made
    end

    it "bans when CF-IPCountry header is missing" do
      post_check_status({ idfa: idfa, rooted_device: false }, "CF-IPCountry" => nil)

      expect(response.parsed_body).to eq("ban_status" => "banned")
    end

    it "bans when rooted_device is true" do
      post_check_status(idfa: idfa, rooted_device: true)

      expect(response.parsed_body).to eq("ban_status" => "banned")
    end

    it "bans when VPNAPI reports vpn" do
      stub_vpnapi(ip: "127.0.0.1", vpn: true)

      post_check_status(idfa: idfa, rooted_device: false)

      expect(response.parsed_body).to eq("ban_status" => "banned")
    end

    it "bans when VPNAPI reports tor" do
      stub_vpnapi(ip: "127.0.0.1", tor: true)

      post_check_status(idfa: idfa, rooted_device: false)

      expect(response.parsed_body).to eq("ban_status" => "banned")
    end
  end

  describe "user handling" do
    it "returns banned without new log for already banned user" do
      create(:user, idfa: idfa, ban_status: :banned)

      expect {
        post_check_status(idfa: idfa, rooted_device: false)
      }.not_to change(IntegrityLog, :count)

      expect(response.parsed_body).to eq("ban_status" => "banned")
      expect(a_request(:get, %r{https://vpnapi.io/api/})).not_to have_been_made
    end

    it "re-runs checks and logs when not_banned user becomes banned" do
      create(:user, idfa: idfa, ban_status: :not_banned)

      expect {
        post_check_status(idfa: idfa, rooted_device: true)
      }.to change(IntegrityLog, :count).by(1)

      expect(User.find_by!(idfa: idfa).ban_status).to eq("banned")
    end

    it "does not log when not_banned user stays not_banned" do
      create(:user, idfa: idfa, ban_status: :not_banned)

      expect {
        post_check_status(idfa: idfa, rooted_device: false)
      }.not_to change(IntegrityLog, :count)

      expect(User.where(idfa: idfa).count).to eq(1)
    end
  end

  describe "validation" do
    it "returns 422 for invalid UUID" do
      post_check_status(idfa: "not-a-uuid", rooted_device: false)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 400 for missing idfa" do
      post_check_status(rooted_device: false)

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 for missing rooted_device" do
      post_check_status(idfa: idfa)

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 422 for non-boolean rooted_device" do
      post_check_status(idfa: idfa, rooted_device: "yes")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 400 for malformed JSON" do
      post "/v1/user/check_status", params: "{", headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 for missing Content-Type" do
      post "/v1/user/check_status", params: { idfa: idfa, rooted_device: false }.to_json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "VPNAPI fail-open" do
    it "returns not_banned when VPNAPI fails with 500" do
      stub_vpnapi(ip: "127.0.0.1", status: 500)

      post_check_status(idfa: SecureRandom.uuid, rooted_device: false)

      expect(response.parsed_body).to eq("ban_status" => "not_banned")
    end

    it "returns not_banned when VPNAPI fails with 429" do
      stub_vpnapi(ip: "127.0.0.1", status: 429)

      post_check_status(idfa: SecureRandom.uuid, rooted_device: false)

      expect(response.parsed_body).to eq("ban_status" => "not_banned")
    end
  end
end
