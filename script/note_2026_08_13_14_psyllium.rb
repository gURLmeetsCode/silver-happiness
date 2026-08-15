# frozen_string_literal: true

# Day notes only for the psyllium trial — do NOT create a separate meal entry.
# Psyllium belongs inside the meal you build (e.g. fiber greens), not as a
# duplicate "Psyllium husk (morning)" shortcut.
#
# Also removes mistaken auto-logged morning entries if they still exist.
#
#   bin/rails runner script/note_2026_08_13_14_psyllium.rb

DATES = [ Date.new(2026, 8, 13), Date.new(2026, 8, 14) ].freeze
NOTE = "Psyllium AM: regularity ↑, appetite unchanged so far (logged inside fiber greens / built meals — not as a separate entry)."
STALE_MEAL_NAME = "Psyllium husk (morning)"

DATES.each do |date|
  log = DailyLog.find_or_create_by!(logged_on: date)

  removed = log.meal_entries.where(name: STALE_MEAL_NAME).destroy_all
  puts "  #{date}: removed #{removed.size} stale '#{STALE_MEAL_NAME}' entr#{removed.size == 1 ? "y" : "ies"}" if removed.any?

  unless [ log.notes, log.energy_notes ].compact_blank.any? { |n| n.include?("Psyllium AM") }
    log.notes = [ log.notes, NOTE ].compact_blank.join(" · ")
    log.save!
    puts "  #{date}: noted"
  else
    puts "  #{date}: note already present"
  end
end

puts "==> Done"
