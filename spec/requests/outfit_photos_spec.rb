# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Outfit photos", type: :request do
  describe "GET /outfit_photos" do
    it "lists photos" do
      create(:outfit_photo, caption: "Sunday best")

      get outfit_photos_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sunday best")
    end

    it "filters by category" do
      create(:outfit_photo, category: :workout, caption: "Gym fit")
      create(:outfit_photo, category: :everyday, caption: "Errands")

      get outfit_photos_path, params: { category: "workout" }

      expect(response.body).to include("Gym fit")
      expect(response.body).not_to include("Errands")
    end
  end

  describe "GET /outfit_photos/new" do
    it "renders the upload form" do
      get new_outfit_photo_path

      expect(response).to have_http_status(:ok)
    end

    it "accepts a prefilled date and category" do
      get new_outfit_photo_path, params: { logged_on: "2026-08-08", category: "workout" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /outfit_photos" do
    it "saves the photo and returns to its category" do
      expect {
        post outfit_photos_path, params: {
          outfit_photo: {
            logged_on: Date.current, category: "feeling_cute",
            caption: "Nice", image: sample_image_upload
          }
        }
      }.to change(OutfitPhoto, :count).by(1)

      expect(response).to redirect_to(outfit_photos_path(category: "feeling_cute"))
    end

    it "re-renders with 422 when the image is missing" do
      post outfit_photos_path, params: {
        outfit_photo: { logged_on: Date.current, category: "everyday" }
      }

      expect(response).to have_http_status(422)
    end
  end

  describe "DELETE /outfit_photos/:id" do
    it "removes the photo" do
      photo = create(:outfit_photo)

      delete outfit_photo_path(photo)

      expect(response).to redirect_to(outfit_photos_path)
      expect(OutfitPhoto.exists?(photo.id)).to be false
    end
  end
end
