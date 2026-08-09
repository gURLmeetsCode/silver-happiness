# frozen_string_literal: true

require "rails_helper"

# iOS Safari treats the `capture` attribute as "camera only" and drops Photo
# Library from the picker, so an existing photo cannot be uploaded at all.
RSpec.describe "Photo upload pickers", type: :request do
  it "lets the outfit form reach the photo library" do
    get new_outfit_photo_path(category: :feeling_cute)

    expect(response.body).to include('accept="image/*"')
    expect(response.body).not_to include("capture=")
  end

  it "lets the progress photo form reach the photo library" do
    Goal.current

    get daily_log_path(DailyLog.today)

    expect(response.body).to include("progress_photo[image]")
    expect(response.body).not_to include("capture=")
  end

  # The day log opens on Food & drink, so landing there after an upload hides
  # the photo that was just added.
  describe "after uploading" do
    let(:daily_log) { DailyLog.today }

    it "returns to the photos tab" do
      post daily_log_progress_photos_path(daily_log), params: {
        progress_photo: { photo_type: "front", image: sample_image_upload }
      }

      expect(response).to redirect_to(daily_log_path(daily_log, anchor: "photos"))
    end

    it "returns to the photos tab after removing a photo" do
      photo = create(:progress_photo, daily_log: daily_log)

      delete daily_log_progress_photo_path(daily_log, photo)

      expect(response).to redirect_to(daily_log_path(daily_log, anchor: "photos"))
    end

    it "shows the uploaded photo on the day page" do
      create(:progress_photo, daily_log: daily_log, photo_type: :front)
      Goal.current

      get daily_log_path(daily_log)

      expect(response.body).to include("rails/active_storage")
    end
  end
end
