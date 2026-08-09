# frozen_string_literal: true

module ErrorReporting
  extend ActiveSupport::Concern

  included do
    # Missing records are an expected outcome (stale bookmarks, deleted recipes),
    # so they must resolve to 404 in every environment rather than falling through
    # to the catch-all below and being reported as a crash.
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_bad_request

    rescue_from StandardError, with: :render_server_error unless Rails.application.config.consider_all_requests_local
  end

  private

  def render_not_found(_error)
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "not_found" }, status: :not_found }
      format.any { head :not_found }
    end
  end

  def render_bad_request(_error)
    respond_to do |format|
      format.html { render file: Rails.public_path.join("400.html"), status: :bad_request, layout: false }
      format.json { render json: { error: "bad_request" }, status: :bad_request }
      format.any { head :bad_request }
    end
  end

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
