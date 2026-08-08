# frozen_string_literal: true

module ErrorReporting
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :render_server_error unless Rails.application.config.consider_all_requests_local
  end

  private

  def render_server_error(error)
    capture_error(error)
    render file: Rails.public_path.join("500.html"), status: :internal_server_error, layout: false
  end

  def capture_error(error)
    path = Rails.root.join("tmp/last_error.txt")
    body = [
      Time.current.iso8601,
      "#{error.class}: #{error.message}",
      *error.backtrace.to_a.first(8)
    ].join("\n")
    path.write(body)
  rescue StandardError
    nil
  end
end
