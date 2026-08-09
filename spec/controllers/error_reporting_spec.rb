# frozen_string_literal: true

require "rails_helper"

# Production is the only environment that registers the StandardError catch-all,
# so an ordering bug in ErrorReporting is invisible to an ordinary request spec:
# a missing record 404s correctly in test and 500s on the Pi. These build the
# production handler set explicitly and ask Rails which handler it really picks.
RSpec.describe ErrorReporting do
  def controller_with(rescue_everything:)
    klass = Class.new do
      include ActiveSupport::Rescuable
      extend ErrorReporting::ClassMethods

      attr_reader :handled

      def initialize
        @handled = []
      end

      def render_not_found(_error) = @handled << :not_found
      def render_bad_request(_error) = @handled << :bad_request
      def render_server_error(_error) = @handled << :server_error
    end

    klass.install_error_handlers(rescue_everything: rescue_everything)
    klass.new
  end

  context "when the catch-all is active, as in production" do
    let(:controller) { controller_with(rescue_everything: true) }

    it "answers a missing record with 404 rather than 500" do
      controller.rescue_with_handler(ActiveRecord::RecordNotFound.new("no Recipe 14"))

      expect(controller.handled).to eq([ :not_found ])
    end

    it "answers missing params with 400 rather than 500" do
      controller.rescue_with_handler(ActionController::ParameterMissing.new(:recipe))

      expect(controller.handled).to eq([ :bad_request ])
    end

    it "still catches genuinely unexpected errors" do
      controller.rescue_with_handler(RuntimeError.new("boom"))

      expect(controller.handled).to eq([ :server_error ])
    end
  end

  context "when the catch-all is off, as in development and test" do
    let(:controller) { controller_with(rescue_everything: false) }

    it "still answers a missing record with 404" do
      controller.rescue_with_handler(ActiveRecord::RecordNotFound.new("no Recipe 14"))

      expect(controller.handled).to eq([ :not_found ])
    end

    it "lets unexpected errors through to the Rails error page" do
      controller.rescue_with_handler(RuntimeError.new("boom"))

      expect(controller.handled).to be_empty
    end
  end
end
