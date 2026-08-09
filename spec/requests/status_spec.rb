# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Status", type: :request do
  describe "GET /status" do
    it "renders the status page" do
      get status_path

      expect(response).to have_http_status(:ok)
    end
  end
end
