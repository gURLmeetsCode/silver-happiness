# frozen_string_literal: true

class GroceryChecksController < ApplicationController
  def toggle
    period = ShoppingPeriod.current
    item_key = params.require(:item_key)
    checked = GroceryCheck.toggle!(period: period, item_key: item_key)

    render json: { checked: checked, item_key: item_key }
  end

  def reset
    period = ShoppingPeriod.current
    GroceryCheck.for_period(period).delete_all

    redirect_to grocery_recipes_path, notice: "Grocery list cleared for #{ShoppingPeriod.label(period)}."
  end
end
