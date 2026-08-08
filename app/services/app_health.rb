# frozen_string_literal: true

class AppHealth
  Result = Struct.new(:status, :checks, :issues, :checked_at, :revision, :last_error, keyword_init: true) do
    def ok?
      status == "ok"
    end

    def http_status
      ok? ? :ok : :service_unavailable
    end
  end

  def self.check
    new.check
  end

  def check
    issues = []
    checks = {}

    check_database(checks, issues)
    check_migrations(checks, issues)
    check_app_smoke(checks, issues)

    Result.new(
      status: issues.empty? ? "ok" : "error",
      checks: checks,
      issues: issues,
      checked_at: Time.current.iso8601,
      revision: read_revision,
      last_error: read_last_error
    )
  end

  private

  def check_database(checks, issues)
    ActiveRecord::Base.connection.execute("SELECT 1")
    checks[:database] = "ok"
  rescue StandardError => e
    checks[:database] = "error"
    issues << "Database: #{e.message}"
  end

  def check_migrations(checks, issues)
    applied = ActiveRecord::Base.connection.select_values("SELECT version FROM schema_migrations")
    all_versions = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)
      .migrations.map { |m| m.version.to_s }
    pending = all_versions - applied

    if pending.any?
      checks[:migrations] = "pending"
      issues << "#{pending.size} pending migration(s): #{pending.join(', ')}"
    else
      checks[:migrations] = "ok"
    end
  rescue StandardError => e
    checks[:migrations] = "error"
    issues << "Migration check: #{e.message}"
  end

  def check_app_smoke(checks, issues)
    Product.quick_log.load
    log = DailyLog.includes(:workouts, :strength_sessions).new(logged_on: Date.current)
    log.calories_burned
    Goal.current
    checks[:app] = "ok"
  rescue StandardError => e
    checks[:app] = "error"
    issues << "App code: #{e.class} — #{e.message}"
  end

  def read_revision
    path = Rails.root.join("tmp/revision")
    return path.read.strip if path.exist?

    `git rev-parse --short HEAD 2>/dev/null`.strip.presence
  rescue StandardError
    nil
  end

  def read_last_error
    path = Rails.root.join("tmp/last_error.txt")
    return nil unless path.exist?

    path.read.strip.truncate(2000)
  end
end
