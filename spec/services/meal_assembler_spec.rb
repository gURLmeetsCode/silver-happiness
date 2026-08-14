# frozen_string_literal: true

require "rails_helper"

RSpec.describe MealAssembler do
  # Same shape as the real products: a serving label that names its own unit.
  let(:zucchini) do
    create(:product, name: "Zucchini", default_serving_g: 100, serving_label: "½ zucchini (~100 g)",
      calories_per_100g: 17, protein_per_100g: 1.2, carbs_per_100g: 3.1, fat_per_100g: 0.3)
  end

  let(:tofu) do
    create(:product, name: "Tofu", default_serving_g: 125, serving_label: "1 pavé (125 g)",
      calories_per_100g: 145, protein_per_100g: 16, carbs_per_100g: 2, fat_per_100g: 8)
  end

  let(:olive_oil) do
    create(:product, name: "Olive oil", default_serving_g: 10, serving_label: "1 tbsp (10 g)",
      calories_per_100g: 900, protein_per_100g: 0, carbs_per_100g: 0, fat_per_100g: 100)
  end

  describe "units" do
    it "treats a serving as the product's own portion" do
      # Half a 125 g pavé of tofu.
      expect(tofu.grams_for(0.5, "serving")).to eq(62.5)
    end

    it "reads density off the serving label instead of assuming water" do
      # "1 tbsp (10 g)" means 10 g per 15 ml, so a teaspoon is 3.3 g, not 5 g.
      expect(olive_oil.grams_per_ml).to be_within(0.01).of(0.667)
      expect(olive_oil.grams_for(0.5, "tsp")).to be_within(0.1).of(1.7)
    end

    it "falls back to water density when the label names no volume" do
      expect(zucchini.grams_per_ml).to eq(1.0)
      expect(zucchini.grams_for(0.5, "cup")).to eq(120.0)
    end

    it "offers the product's own serving as the first unit" do
      expect(tofu.unit_options.first).to eq([ "1 pavé (125 g)", "serving" ])
    end
  end

  describe "assembling tonight's dinner" do
    subject(:assembler) do
      described_class.new({
        "0" => { "product_id" => zucchini.id, "quantity" => "0.5", "unit" => "cup" },
        "1" => { "product_id" => tofu.id, "quantity" => "0.5", "unit" => "serving" },
        "2" => { "product_id" => olive_oil.id, "quantity" => "0.5", "unit" => "tsp" }
      })
    end

    it "adds up the calories" do
      # 120 g zucchini = 20, 62.5 g tofu = 91, 1.7 g oil = 15
      expect(assembler.totals[:calories]).to eq(126)
    end

    it "adds up the protein" do
      expect(assembler.totals[:protein]).to be_within(0.2).of(11.4)
    end

    it "names the meal from the items" do
      expect(assembler.suggested_name).to eq("Zucchini, Tofu + 1 more")
    end

    it "records what went in and how much" do
      expect(assembler.notes).to include("0.5 cup Zucchini (120 g)")
      expect(assembler.notes).to include("Tofu (63 g)")
    end
  end

  describe "picker rows (products and scaled batches)" do
    it "accepts product_ID picker values" do
      assembler = described_class.new({
        "0" => { "picker" => "product_#{tofu.id}", "quantity" => "1", "unit" => "serving" }
      })

      expect(assembler.components.first.grams).to eq(125)
    end

    it "expands a meal template as a scaled batch" do
      template = create(:meal_template, name: "Roasted potatoes (batch)", slug: "test-roast-batch")
      create(:meal_template_item, meal_template: template, product: zucchini, quantity_g: 400)
      create(:meal_template_item, meal_template: template, product: tofu, quantity_g: 200)

      assembler = described_class.new({
        "0" => { "picker" => "template_#{template.id}", "quantity" => "0.25", "unit" => "serving" }
      })

      expect(assembler.components.map { |c| [ c.product.name, c.grams ] }).to contain_exactly(
        [ "Zucchini", 100.0 ],
        [ "Tofu", 50.0 ]
      )
      expect(assembler.suggested_name).to eq("Roasted potatoes (batch)")
      expect(assembler.notes).to include("0.25× Roasted potatoes (batch)")
    end

    it "mixes a batch with a product in one meal" do
      template = create(:meal_template, name: "Zucchini tofu batch")
      create(:meal_template_item, meal_template: template, product: zucchini, quantity_g: 400)
      create(:meal_template_item, meal_template: template, product: tofu, quantity_g: 300)

      assembler = described_class.new({
        "0" => { "picker" => "template_#{template.id}", "quantity" => "0.5", "unit" => "serving" },
        "1" => { "picker" => "product_#{olive_oil.id}", "quantity" => "1", "unit" => "tsp" }
      })

      expect(assembler).to be_any
      expect(assembler.suggested_name).to include("Zucchini tofu batch")
      expect(assembler.totals[:calories]).to be > 0
    end
  end

  describe "rows that should be ignored" do
    it "skips a row with no product" do
      assembler = described_class.new({ "0" => { "product_id" => "", "quantity" => "2", "unit" => "cup" } })

      expect(assembler).not_to be_any
    end

    it "skips a row with no amount" do
      assembler = described_class.new({ "0" => { "product_id" => tofu.id, "quantity" => "", "unit" => "g" } })

      expect(assembler).not_to be_any
    end

    it "accepts a comma as a decimal separator" do
      assembler = described_class.new({ "0" => { "product_id" => tofu.id, "quantity" => "0,5", "unit" => "serving" } })

      expect(assembler.components.first.grams).to eq(62.5)
    end
  end
end
