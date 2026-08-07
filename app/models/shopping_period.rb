# frozen_string_literal: true

# Grocery lists reset on each shopping day: Tuesday and Saturday.
# Checked items belong to the most recent Tue/Sat on or before today.
class ShoppingPeriod
  SHOPPING_DAYS = [ 2, 6 ].freeze # Tuesday, Saturday

  def self.current(on: Date.current)
    date = on.to_date
    loop do
      return date if SHOPPING_DAYS.include?(date.wday)

      date -= 1.day
    end
  end

  def self.next(on: Date.current)
    date = on.to_date + 1.day
    loop do
      return date if SHOPPING_DAYS.include?(date.wday)

      date += 1.day
    end
  end

  def self.label(period_date)
    period_date = period_date.to_date
    day = period_date.strftime("%A")
    "#{day} #{period_date.strftime('%-d %b %Y')}"
  end

  def self.shopping_day?(date = Date.current)
    SHOPPING_DAYS.include?(date.to_date.wday)
  end
end
