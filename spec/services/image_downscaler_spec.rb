# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageDownscaler do
  def upload_of(width:, height:, content_type: "image/jpeg")
    path = Rails.root.join("tmp", "downscaler-#{width}x#{height}-#{SecureRandom.hex(4)}.jpg")
    MiniMagick::Tool::Convert.new do |convert|
      convert.size("#{width}x#{height}")
      convert << "xc:pink"
      convert << path.to_s
    end

    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(path),
      filename: File.basename(path),
      type: content_type
    )
  end

  it "shrinks a photo larger than the limit" do
    upload = upload_of(width: 3000, height: 2000)

    described_class.call(upload)

    resized = MiniMagick::Image.new(upload.tempfile.path)
    expect(resized.width).to eq(described_class::MAX_EDGE)
    expect(resized.height).to eq(1067)
  end

  it "leaves a photo that is already small alone" do
    upload = upload_of(width: 800, height: 600)

    described_class.call(upload)

    untouched = MiniMagick::Image.new(upload.tempfile.path)
    expect(untouched.width).to eq(800)
    expect(untouched.height).to eq(600)
  end

  it "returns the upload so the caller can attach it" do
    upload = upload_of(width: 3000, height: 2000)

    expect(described_class.call(upload)).to equal(upload)
  end

  # A photo you took matters more than a tidy file size.
  it "never blocks an upload it cannot process" do
    not_an_image = ActionDispatch::Http::UploadedFile.new(
      tempfile: Tempfile.new("notes").tap { |f| f.write("hello") && f.rewind },
      filename: "notes.txt",
      type: "text/plain"
    )

    expect(described_class.call(not_an_image)).to equal(not_an_image)
  end

  it "survives a corrupt image without raising" do
    broken = ActionDispatch::Http::UploadedFile.new(
      tempfile: Tempfile.new([ "broken", ".jpg" ]).tap { |f| f.write("not really a jpeg") && f.rewind },
      filename: "broken.jpg",
      type: "image/jpeg"
    )

    expect { described_class.call(broken) }.not_to raise_error
  end
end
