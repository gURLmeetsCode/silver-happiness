# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Urge check-ins", type: :request do
  let(:today) { DailyLog.today }

  describe "GET /daily_logs/:daily_log_id/urge_check_ins/new" do
    it "renders the pause flow with today's protein" do
      create(:meal_entry, daily_log: today, protein_g: 40, calories: 400)

      get new_daily_log_urge_check_in_path(today)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pause the spiral")
      expect(response.body).to include("40")
      expect(response.body).to include("urge_check_in[feeling]")
      expect(response.body).to include("urge_check_in[outcome]")
    end
  end

  describe "POST /daily_logs/:daily_log_id/urge_check_ins" do
    it "saves a paused urge and returns home" do
      expect {
        post daily_log_urge_check_ins_path(today), params: {
          urge_check_in: {
            feeling: "stressed",
            protein_status: "no",
            delay_action: "tea",
            outcome: "paused",
            note: "Made tea instead"
          },
          return_to: root_path
        }
      }.to change(UrgeCheckIn, :count).by(1)

      expect(response).to redirect_to(root_path)
      urge = today.urge_check_ins.last
      expect(urge).to be_paused
      expect(urge.feeling).to eq("stressed")
      expect(urge.note).to eq("Made tea instead")
    end

    it "saves an ate-anyway urge without shame wording failure" do
      post daily_log_urge_check_ins_path(today), params: {
        urge_check_in: {
          feeling: "already_ruined",
          protein_status: "unsure",
          delay_action: "wait",
          outcome: "ate_anyway"
        },
        return_to: daily_log_path(today, anchor: "body")
      }

      expect(response).to redirect_to(daily_log_path(today, anchor: "body"))
      follow_redirect!
      expect(response.body).to include("Ate anyway")
      expect(flash[:notice]).to include("No shame")
    end
  end

  describe "home entry point" do
    it "links to the urge pause from the home screen" do
      get root_path

      expect(response.body).to include(new_daily_log_urge_check_in_path(today))
      expect(response.body).to include("I’m about to spiral")
    end
  end
end
