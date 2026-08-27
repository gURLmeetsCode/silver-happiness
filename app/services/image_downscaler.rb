# frozen_string_literal: true

# Shrinks a photo as it is uploaded, so the stored file is already the size we
# want to display. Active Storage variants would be the usual answer, but they
# require the image_processing gem, which drags in ruby-vips, and Rails 8 will
# not boot against the libvips 8.10 on Raspbian Bullseye.
#
# Keep edges modest and JPEG quality capped — the Pi serves every byte over
# Tailscale, and phone photos otherwise stay hundreds of KB after resize alone.
class ImageDownscaler
  MAX_EDGE = 1200
  JPEG_QUALITY = 82

  def self.call(uploaded)
    new(uploaded).call
  end

  def initialize(uploaded)
    @uploaded = uploaded
  end

  # Always returns the upload. A photo you took is worth more than a tidy file
  # size, so a failure to resize must never block saving it.
  def call
    return @uploaded unless resizable?

    image = MiniMagick::Image.new(@uploaded.tempfile.path)
    oversized = [ image.width, image.height ].max > MAX_EDGE

    image.auto_orient
    image.resize "#{MAX_EDGE}x#{MAX_EDGE}>" if oversized
    image.strip
    image.quality JPEG_QUALITY if jpeg?(image)
    @uploaded
  rescue StandardError => e
    Rails.logger.warn("ImageDownscaler skipped: #{e.class}: #{e.message}")
    @uploaded
  end

  private

  def resizable?
    @uploaded.respond_to?(:tempfile) &&
      @uploaded.content_type.to_s.start_with?("image/") &&
      File.exist?(@uploaded.tempfile.path)
  end

  def jpeg?(image)
    format = image.type.to_s.downcase
    format.in?(%w[jpeg jpg]) || @uploaded.content_type.to_s.match?(%r{\Aimage/jpe?g\z}i)
  end
end
