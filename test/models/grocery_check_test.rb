# frozen_string_literal: true

require "test_helper"

class GroceryCheckTest < ActiveSupport::TestCase
  setup do
    @period = Date.new(2026, 8, 5)
  end

  test "toggle creates checked item" do
    assert GroceryCheck.toggle!(period: @period, item_key: "staple:produce:abc")
    assert GroceryCheck.checked?(period: @period, item_key: "staple:produce:abc")
  end

  test "toggle again unchecks" do
    GroceryCheck.toggle!(period: @period, item_key: "staple:produce:abc")
    refute GroceryCheck.toggle!(period: @period, item_key: "staple:produce:abc")
  end

  test "checks are scoped to shopping period" do
    GroceryCheck.create!(shopping_period: @period, item_key: "item-1", checked: true)
    other = Date.new(2026, 8, 9)
    refute GroceryCheck.checked?(period: other, item_key: "item-1")
  end
end
