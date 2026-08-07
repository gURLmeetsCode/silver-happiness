# frozen_string_literal: true

require "test_helper"

class ShoppingPeriodTest < ActiveSupport::TestCase
  test "current period is Tuesday when today is Friday after Tuesday" do
    friday = Date.new(2026, 8, 7)
    assert_equal Date.new(2026, 8, 4), ShoppingPeriod.current(on: friday)
  end

  test "current period is Saturday when today is Saturday" do
    saturday = Date.new(2026, 8, 8)
    assert_equal saturday, ShoppingPeriod.current(on: saturday)
  end

  test "current period is Saturday when today is Sunday" do
    sunday = Date.new(2026, 8, 9)
    assert_equal Date.new(2026, 8, 8), ShoppingPeriod.current(on: sunday)
  end

  test "next reset after Friday is Saturday" do
    friday = Date.new(2026, 8, 7)
    assert_equal Date.new(2026, 8, 8), ShoppingPeriod.next(on: friday)
  end

  test "next reset after Saturday is Tuesday" do
    saturday = Date.new(2026, 8, 8)
    assert_equal Date.new(2026, 8, 11), ShoppingPeriod.next(on: saturday)
  end
end
