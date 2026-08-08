class StatusController < ApplicationController
  layout false

  def show
    @health = AppHealth.check
  end
end
