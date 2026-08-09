# frozen_string_literal: true

require "rails_helper"

# Guards against two failure modes that have reached production before:
#   1. A route pointing at a controller action that does not exist (500 on hit).
#   2. An action shipped with no request spec covering it.
RSpec.describe "Route coverage" do
  APP_ROUTES = Rails.application.routes.routes.filter_map do |route|
    controller = route.defaults[:controller]
    action = route.defaults[:action]
    next if controller.blank? || action.blank?
    next if controller.start_with?("rails/", "active_storage/", "action_mailbox/", "turbo/")

    { controller: controller, action: action }
  end.uniq.freeze

  it "declares at least one route" do
    expect(APP_ROUTES).not_to be_empty
  end

  describe "every route resolves to an implemented action" do
    APP_ROUTES.each do |route|
      it "#{route[:controller]}##{route[:action]} exists" do
        klass = "#{route[:controller]}_controller".camelize.constantize

        expect(klass.action_methods).to include(route[:action]),
          "#{klass}##{route[:action]} is routed but not implemented — hitting this route returns a 500"
      end
    end
  end

  it "has a request spec file for every routed controller" do
    routed = APP_ROUTES.map { |r| r[:controller] }.uniq
    spec_files = Dir[Rails.root.join("spec/requests/**/*_spec.rb")].map { |f| File.basename(f, "_spec.rb") }

    missing = routed.reject do |controller|
      name = controller.tr("/", "_")
      spec_files.include?(name) || spec_files.include?(name.singularize)
    end

    expect(missing).to be_empty,
      "No request spec for: #{missing.join(', ')}. Add spec/requests/<controller>_spec.rb."
  end
end
