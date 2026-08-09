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
end
