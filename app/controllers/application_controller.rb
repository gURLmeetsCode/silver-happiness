class ApplicationController < ActionController::Base
  include ErrorReporting

  # Self-hosted app: allow mobile Safari 15+ (default :modern requires Safari 17.2+)
  allow_browser versions: { safari: 15, chrome: 90, firefox: 90, ie: false }

  helper_method :safe_return_to

  private

  # Forms pass a `return_to` so Save lands back where you started. Only
  # same-origin paths are honoured, so a crafted link cannot turn a Cancel
  # button or a redirect into a jump off-site.
  def safe_return_to(default: nil)
    path = params[:return_to].to_s

    return default unless path.start_with?("/")
    return default if path.start_with?("//", "/\\")

    path
  end
end
