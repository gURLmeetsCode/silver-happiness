# frozen_string_literal: true

module GroceryHelper
  def grocery_checkbox(item_key, label, checked_keys:, meta: nil, recipe: nil)
    checked = checked_keys.include?(item_key)
    tag.label(class: "grocery-item d-flex align-items-start gap-3 py-2 #{checked ? 'grocery-item--checked' : ''}",
              data: { item_key: item_key }) do
      check_box_tag(
        "grocery[#{item_key}]",
        "1",
        checked,
        class: "form-check-input grocery-item__checkbox flex-shrink-0 mt-1",
        data: { action: "grocery-list#toggle", grocery_list_target: "checkbox", item_key: item_key }
      ) +
        tag.div(class: "flex-grow-1") do
          tag.span(label, class: "grocery-item__label #{checked ? 'text-decoration-line-through text-muted' : ''}") +
            (meta.present? ? tag.div(meta, class: "small text-muted") : "") +
            (recipe.present? ? tag.div(link_to("Recipe", recipe_path(recipe), class: "small"), class: "mt-1") : "")
        end
    end
  end

  def staple_item_key(category, label)
    GroceryCheck.staple_key(category, label)
  end

  def batch_prep_grocery_items(batch_prep)
    items = [ { key: "batch:veg", label: "Wash/chop salad veg into containers" } ]
    {
      "baked-tofu" => "Bake 2 blocks tofu",
      "quinoa-batch" => "Cook pot of quinoa",
      "balsamic-dressing" => "Mix balsamic dressing"
    }.each do |slug, label|
      next unless batch_prep[slug]

      items << { key: "batch:#{slug}", label: label, recipe: batch_prep[slug] }
    end
    items
  end

  def grocery_total_count(staples, grouped, batch_items)
    staples.values.sum(&:size) + grouped.values.sum(&:size) + batch_items.size
  end
end
