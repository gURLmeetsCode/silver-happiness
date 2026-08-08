class HealthController < ActionController::Base
  # No auth — Tailscale-only network. Plain controller skips app before_actions.
  layout false

  def show
    result = AppHealth.check

    respond_to do |format|
      format.json do
        render json: {
          status: result.status,
          checks: result.checks,
          issues: result.issues,
          checked_at: result.checked_at,
          revision: result.revision,
          last_error: result.last_error
        }, status: result.http_status
      end
      format.html { redirect_to status_path }
      format.any { head result.http_status }
    end
  end
end
