# frozen_string_literal: true

# Builds one meal out of several things you ate: half a cup of pasta, a quarter
# of a roasted-potato batch, a side of tofu. Rows are either a product with an
# amount/unit, or a saved meal template scaled as "× batch".
class MealAssembler
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

  def parse_quantity(raw)
    raw.to_s.tr(",", ".").to_f
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
