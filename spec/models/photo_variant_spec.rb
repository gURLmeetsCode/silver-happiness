# frozen_string_literal: true

require "rails_helper"

# Active Storage builds a variant URL lazily, so a spec that only renders a page
# passes even when the transform itself is impossible. These force the transform
# to actually run, which is what the browser triggers when it fetches the image.
RSpec.describe "Photo thumbnails" do
  it "generates a progress photo thumbnail" do
    photo = create(:progress_photo)

    expect { photo.image.variant(resize_to_limit: [ 400, 600 ]).processed }
      .not_to raise_error
  end

  it "generates an outfit photo thumbnail" do
    photo = create(:outfit_photo)

    expect { photo.image.variant(resize_to_limit: [ 600, 800 ]).processed }
      .not_to raise_error
  end

  it "produces an image that is actually readable" do
    photo = create(:progress_photo)

    variant = photo.image.variant(resize_to_limit: [ 400, 600 ]).processed

    expect(variant.image.blob.byte_size).to be_positive
  end
end
