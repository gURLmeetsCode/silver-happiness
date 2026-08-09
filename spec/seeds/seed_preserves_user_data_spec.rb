# frozen_string_literal: true

require "rails_helper"

# db:seed runs by hand on the Pi against a database full of real check-ins.
# It must only ever add reference data — never rewrite or delete something
# that was logged through the app.
RSpec.describe "db:seed against a database with real data" do
  def run_seed!
    original = $RECIPES_SEED_HELPER_ONLY
    $RECIPES_SEED_HELPER_ONLY = false
    original_stdout = $stdout
    $stdout = StringIO.new
    load Rails.root.join("db/seeds/production.rb")
  ensure
    $stdout = original_stdout
    $RECIPES_SEED_HELPER_ONLY = original
  end

  def snapshot(record)
    record.reload.attributes.except("updated_at")
  end

  describe "days the seed also knows about" do
    # Aug 6 and Aug 7 2026 are hardcoded in db/seeds/baseline_data.rb.
    [ Date.new(2026, 8, 6), Date.new(2026, 8, 7) ].each do |date|
      it "leaves an existing #{date} log exactly as it was" do
        log = create(:daily_log, logged_on: date, weight_kg: 58.2, water_ml: 900,
                     feeling_check_in: "My own note")
        entry = create(:meal_entry, daily_log: log, name: "My own dinner",
                       calories: 777, protein_g: 42)
        before_log = snapshot(log)
        before_entry = snapshot(entry)

        run_seed!

        expect(snapshot(log)).to eq(before_log)
        expect(snapshot(entry)).to eq(before_entry)
        expect(log.reload.meal_entries.pluck(:name)).to eq([ "My own dinner" ])
      end
    end

    it "does not resurrect a seeded meal the user deleted" do
      log = create(:daily_log, logged_on: Date.new(2026, 8, 7))
      log.meal_entries.destroy_all

      run_seed!

      expect(log.reload.meal_entries).to be_empty
    end
  end

  describe "recent days the seed knows nothing about" do
    it "leaves yesterday and the day before untouched" do
      recent = [ Date.yesterday, 2.days.ago.to_date ].map do |date|
        log = create(:daily_log, logged_on: date, weight_kg: 60.1, water_ml: 1500)
        create(:meal_entry, daily_log: log, name: "Logged by hand", calories: 512, protein_g: 31)
        create(:workout, daily_log: log, activity_type: :run, calories_burned: 400, distance_km: 7)
        log
      end
      before = recent.map { |log| snapshot(log) }
      entries = recent.flat_map { |log| log.meal_entries.map { |e| snapshot(e) } }

      run_seed!

      expect(recent.map { |log| snapshot(log) }).to eq(before)
      expect(recent.flat_map { |log| log.reload.meal_entries.map { |e| snapshot(e) } }).to eq(entries)
      expect(recent).to all(satisfy { |log| log.reload.workouts.count == 1 })
    end

    it "does not change the number of logged days" do
      3.times { |n| create(:daily_log, logged_on: Date.current - n.days) }

      expect { run_seed! }.not_to change { DailyLog.where("logged_on >= ?", 3.days.ago).count }
    end
  end

  describe "records the user created themselves" do
    it "keeps a user recipe that lands on a seeded slug" do
      recipe = create(:recipe, :user_created, :with_ingredients,
                      slug: "baked-tofu", name: "My baked tofu")
      before = snapshot(recipe)

      run_seed!

      expect(snapshot(recipe)).to eq(before)
      expect(recipe.reload.recipe_ingredients.count).to eq(1)
    end

    it "keeps personal notes on a seeded recipe" do
      run_seed!
      recipe = Recipe.find_by!(slug: "baked-tofu")
      recipe.update!(personal_notes: "Use less oil", reaction: :up)

      run_seed!

      expect(recipe.reload.personal_notes).to eq("Use less oil")
      expect(recipe).to be_reaction_up
    end

    it "keeps the goal display name and targets" do
      goal = Goal.current
      goal.update!(display_name: "Natasha", target_weight_kg: 55.5, water_goal_ml: 2500)

      run_seed!

      goal.reload
      expect(goal.display_name).to eq("Natasha")
      expect(goal.target_weight_kg).to eq(55.5)
      expect(goal.water_goal_ml).to eq(2500)
    end

    it "keeps outfit and progress photos" do
      outfit = create(:outfit_photo)
      progress = create(:progress_photo)

      run_seed!

      expect(OutfitPhoto.exists?(outfit.id)).to be true
      expect(ProgressPhoto.exists?(progress.id)).to be true
    end

    it "keeps a strength session logged against a seeded plan" do
      run_seed!
      log = create(:daily_log, logged_on: Date.current)
      session = create(:strength_session, :with_logs, daily_log: log,
                       workout_plan: WorkoutPlan.first)
      before = snapshot(session)

      run_seed!

      expect(snapshot(session)).to eq(before)
      expect(session.reload.strength_exercise_logs.count).to eq(1)
    end
  end

  it "never reduces the amount of logged data" do
    5.times { |n| create(:daily_log, logged_on: Date.current - n.days) }
    DailyLog.find_each { |log| create(:meal_entry, daily_log: log) }
    before = { logs: DailyLog.count, entries: MealEntry.count }

    run_seed!
    after_first = { logs: DailyLog.count, entries: MealEntry.count }
    run_seed!

    expect(after_first[:logs]).to be >= before[:logs]
    expect(after_first[:entries]).to be >= before[:entries]
    expect(DailyLog.count).to eq(after_first[:logs])
    expect(MealEntry.count).to eq(after_first[:entries])
  end
end
