# frozen_string_literal: true

module UploadHelpers
  def sample_image_upload
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/sample.png"),
      "image/png"
    )
  end
end

RSpec.configure do |config|
  config.include UploadHelpers
end
