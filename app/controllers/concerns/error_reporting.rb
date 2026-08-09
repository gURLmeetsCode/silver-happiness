# frozen_string_literal: true

module ErrorReporting
  extend ActiveSupport::Concern

  included do
    install_error_handlers(rescue_everything: !Rails.application.config.consider_all_requests_local)
  end

  class_methods do
    # Rails picks a rescue_from handler with `rescue_handlers.reverse_each`, so
    # the LAST one registered wins. The catch-all therefore has to be registered
    # first; register it last and it swallows every specific handler below it,
    # turning an expected 404 into a 500 in production only — development and
    # test never register it at all, so tests cannot see the difference.
    def install_error_handlers(rescue_everything:)
      rescue_from StandardError, with: :render_server_error if rescue_everything

      # Missing records are an expected outcome (stale bookmarks, retired
      # recipes) rather than a crash.
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
    end
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
