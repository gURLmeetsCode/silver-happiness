# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "reports status as JSON" do
      get health_path, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["status"]).to eq("ok")
      expect(json["checks"]).to include("database" => "ok")
    end

    it "redirects HTML requests to the status page" do
      get health_path

      expect(response).to redirect_to(status_path)
    end
  end

  describe "GET /up" do
    it "returns 200" do
      get rails_health_check_path

      expect(response).to have_http_status(:ok)
    end
  end
end
