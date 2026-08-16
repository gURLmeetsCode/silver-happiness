# frozen_string_literal: true

# Builds one meal out of several things you ate: half a cup of pasta, a quarter
# of a roasted-potato batch, a side of tofu. Rows are either a product with an
# amount/unit, or a saved meal template scaled as "× batch/serving".
class MealAssembler
  VULGAR_FRACTIONS = {
    "½" => 0.5, "⅓" => 1.0 / 3, "⅔" => 2.0 / 3, "¼" => 0.25, "¾" => 0.75,
    "⅕" => 0.2, "⅖" => 0.4, "⅗" => 0.6, "⅘" => 0.8, "⅙" => 1.0 / 6, "⅛" => 0.125
  }.freeze

  Component = Struct.new(:product, :quantity, :unit, :grams, :nutrition, :source_name, keyword_init: true) do
    def label
      if source_name.present? && unit == "serving"
        "#{formatted_quantity}× #{source_name} → #{product.name} (#{grams.round} g)"
      else
        "#{formatted_quantity} #{unit_label} #{product.name} (#{grams.round} g)"
      end
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

  def suggested_name
    labels = components.filter_map { |c| c.source_name.presence || c.product.name }.uniq
    return labels.first if labels.one?

    "#{labels.first(2).join(', ')}#{" + #{labels.size - 2} more" if labels.size > 2}"
  end

  def notes
    components.map(&:label).join(" · ")
  end

  def apply!(entry, replace_notes: false)
    sum = totals
    entry.calories = sum[:calories].round
    entry.protein_g = sum[:protein].round(1)
    entry.carbs_g = sum[:carbs].round(1)
    entry.fat_g = sum[:fat].round(1)
    entry.name = entry.name.presence || suggested_name
    entry.notes = if replace_notes || entry.notes.blank?
      notes
    else
      [ entry.notes, notes ].compact_blank.join(" · ")
    end
    entry.record_items!(components.map { |c| { product_id: c.product.id, grams: c.grams } })
    entry
  end

  private

  def build_components(items)
    rows_in(items).flat_map { |row| components_for(normalize(row)) }
  end

  def components_for(row)
    quantity = parse_quantity(row["quantity"])
    return [] unless quantity.positive?

    template_id = row["meal_template_id"].presence || template_id_from_picker(row["picker"])
    if template_id
      return expand_template(template_id, quantity)
    end

    product_id = row["product_id"].presence || product_id_from_picker(row["picker"])
    product = Product.find_by(id: product_id)
    return [] unless product

    unit = row["unit"].presence || "g"
    grams = product.grams_for(quantity, unit)
    return [] unless grams.positive?

    [
      Component.new(
        product: product, quantity: quantity, unit: unit,
        grams: grams, nutrition: product.nutrition_for(grams)
      )
    ]
  end

  def expand_template(template_id, scale)
    template = MealTemplate.includes(meal_template_items: :product).find_by(id: template_id)
    return [] unless template

    template.meal_template_items.filter_map do |item|
      grams = item.quantity_g.to_f * scale
      next unless grams.positive? && item.product

      Component.new(
        product: item.product,
        quantity: scale,
        unit: "serving",
        grams: grams,
        nutrition: item.product.nutrition_for(grams),
        source_name: template.name
      )
    end
  end

  def template_id_from_picker(picker)
    picker.to_s[/\Atemplate_(\d+)\z/, 1]
  end

  def product_id_from_picker(picker)
    picker.to_s[/\Aproduct_(\d+)\z/, 1]
  end

  # Match the meal-builder JS: "½", "1/2", "1 1/2", "0.5".
  def parse_quantity(raw)
    text = raw.to_s.strip.tr(",", ".")
    return 0 if text.blank?

    total = 0.0
    matched = false
    VULGAR_FRACTIONS.each do |glyph, value|
      next unless text.include?(glyph)

      total += value
      matched = true
    end

    stripped = text.gsub(/[#{VULGAR_FRACTIONS.keys.join}]/, " ").strip

    if (mixed = stripped.match(/\A(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)\z/))
      return total + mixed[1].to_f + (mixed[2].to_f / mixed[3].to_f)
    end

    if (fraction = stripped.match(/\A(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)\z/))
      return total + (fraction[1].to_f / fraction[2].to_f)
    end

    decimal = stripped.to_f
    return total + decimal if decimal.positive? || stripped.match?(/\A0+(\.0+)?\z/)

    matched ? total : 0.0
  end

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
