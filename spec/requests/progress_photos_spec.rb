# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Progress photos", type: :request do
  before { Goal.current }

  let(:log) { create(:daily_log) }

  describe "POST /daily_logs/:daily_log_id/progress_photos" do
    it "uploads a photo" do
      expect {
        post daily_log_progress_photos_path(log), params: {
          progress_photo: { photo_type: "front", caption: "Week 1", image: sample_image_upload }
        }
      }.to change(ProgressPhoto, :count).by(1)

      expect(response).to redirect_to(daily_log_path(log))
    end

    it "redirects with an alert when the image is missing" do
      post daily_log_progress_photos_path(log), params: {
        progress_photo: { photo_type: "front", caption: "No image" }
      }

      expect(response).to redirect_to(daily_log_path(log))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /daily_logs/:daily_log_id/progress_photos/:id" do
    it "removes the photo" do
      photo = create(:progress_photo, daily_log: log)

      delete daily_log_progress_photo_path(log, photo)

      expect(response).to redirect_to(daily_log_path(log))
      expect(ProgressPhoto.exists?(photo.id)).to be false
    end
  end
end
