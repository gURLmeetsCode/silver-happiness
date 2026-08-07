class ApplicationController < ActionController::Base
  # Self-hosted app: allow mobile Safari 15+ (default :modern requires Safari 17.2+)
  allow_browser versions: { safari: 15, chrome: 90, firefox: 90, ie: false }
end
