# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Journal", type: :request do
  before { Goal.current }

  describe "GET /journal" do
    it "renders today’s check-in and past entries" do
      create(:daily_log, logged_on: Date.current, feeling_check_in: "Good", on_period: true)

      get journal_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Journal")
      expect(response.body).to include("On my period today")
      expect(response.body).to include("Good")
    end

    it "filters past entries by month" do
      create(:daily_log, logged_on: Date.new(2026, 7, 10), notes: "July note")
      create(:daily_log, logged_on: Date.new(2026, 8, 10), notes: "August note")

      get journal_path(month: "2026-07")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("July note")
      expect(response.body).not_to include("August note")
    end
  end
end
