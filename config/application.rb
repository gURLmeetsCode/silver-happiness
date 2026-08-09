require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SilverHappiness
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Pi / Raspbian: use ImageMagick instead of libvips for Active Storage variants
    config.active_storage.variant_processor = :mini_magick

    # Without this the app runs in UTC while you live in CEST, so "today" rolls
    # over at 02:00 local and anything logged after midnight lands on yesterday.
    # The Pi's own clock is set to US Eastern, so pin the zone here rather than
    # relying on whatever the host happens to be.
    config.time_zone = "Europe/Paris"

    # Bed and wake times are wall-clock readings off your phone, not instants:
    # 22:30 means 22:30 whatever the zone. Rails 8 would otherwise shift every
    # stored `time` column by the UTC offset the moment time_zone is set above.
    config.active_record.time_zone_aware_types = [ :datetime ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
