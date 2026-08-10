# frozen_string_literal: true

# Builds one meal out of several things you ate: half a cup of pasta, half a
# courgette, half a teaspoon of oil. Each row is a saved product with an amount
# in whatever unit suits it, and the totals are added up for you.
class MealAssembler
  Component = Struct.new(:product, :quantity, :unit, :grams, :nutrition, keyword_init: true) do
    def label
      "#{formatted_quantity} #{unit_label} #{product.name} (#{grams.round} g)"
    end

    def formatted_quantity
      quantity == quantity.to_i ? quantity.to_i.to_s : quantity.to_s
    end

    def unit_label
      unit == "serving" ? "×" : unit
    end
  end

  attr_reader :components

  def initialize(items)
    @components = build_components(items)
  end

  def any?
    components.any?
  end

  def totals
    components.each_with_object({ calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0 }) do |component, sum|
      sum[:calories] += component.nutrition[:calories]
      sum[:protein] += component.nutrition[:protein]
      sum[:carbs] += component.nutrition[:carbs]
      sum[:fat] += component.nutrition[:fat]
    end
  end

  # "Protein pasta, Zucchini + 2 more" — enough to recognise the meal in a list
  # without having to name it yourself.
  def suggested_name
    names = components.map { |component| component.product.name }
    return names.first if names.one?

    "#{names.first(2).join(', ')}#{" + #{names.size - 2} more" if names.size > 2}"
  end

  def notes
    components.map(&:label).join(" · ")
  end

  def apply!(entry)
    sum = totals
    entry.calories = sum[:calories].round
    entry.protein_g = sum[:protein].round(1)
    entry.carbs_g = sum[:carbs].round(1)
    entry.fat_g = sum[:fat].round(1)
    entry.name = entry.name.presence || suggested_name
    entry.notes = [ entry.notes, notes ].compact_blank.join(" · ")
    entry.record_items!(components.map { |c| { product_id: c.product.id, grams: c.grams } })
    entry
  end

  private

  def build_components(items)
    rows_in(items).filter_map do |row|
      row = normalize(row)
      product = Product.find_by(id: row["product_id"])
      next unless product

      quantity = row["quantity"].to_s.tr(",", ".").to_f
      next unless quantity.positive?

      unit = row["unit"].presence || "g"
      grams = product.grams_for(quantity, unit)
      next unless grams.positive?

      Component.new(
        product: product, quantity: quantity, unit: unit,
        grams: grams, nutrition: product.nutrition_for(grams)
      )
    end
  end

  # Rows arrive keyed by index ("0", "1", …) from the form, but an array is
  # just as valid a way to say the same thing.
  def rows_in(items)
    case items
    when ActionController::Parameters then items.permit!.to_h.values
    when Hash then items.values
    when Array then items
    else []
    end
  end

  def normalize(row)
    case row
    when ActionController::Parameters then row.permit!.to_h
    when Hash then row.stringify_keys
    else {}
    end
  end
end
