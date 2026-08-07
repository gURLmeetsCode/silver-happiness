module ApplicationHelper
  def portions_badge(log)
    return tag.span("—", class: "text-muted") unless log.portions_on_plan

    css = { "yes" => "success", "mostly" => "warning", "no" => "danger" }[log.portions_on_plan]
    tag.span(log.portions_on_plan.humanize, class: "badge text-bg-#{css}")
  end

  def meal_type_label(meal_type)
    meal_type.to_s.humanize
  end

  def outfit_category_options
    OutfitPhoto.categories.keys.map do |key|
      [ OutfitPhoto::CATEGORY_LABELS[key], key ]
    end
  end

  def target_status_badge(status)
    return tag.span("—", class: "text-muted") if status == :unknown

    labels = {
      on_target: [ "On target", "success" ],
      above_target: [ "Above target", "warning" ],
      below_target: [ "Below target", "info" ]
    }
    label, css = labels.fetch(status)
    tag.span(label, class: "badge text-bg-#{css}")
  end

  def weight_vs_goal_label(goal, weight)
    delta = goal.weight_delta(weight)
    return "No weight logged" if delta.nil?

    if delta.zero?
      "At target (#{goal.target_weight_kg} kg)"
    elsif delta.positive?
      "#{delta} kg above target"
    else
      "#{delta.abs} kg below target"
    end
  end

  def nav_active?(key)
    case key.to_sym
    when :today
      controller_name == "dashboard" ||
        (controller_name == "daily_logs" && action_name != "index")
    when :log
      controller_name == "daily_logs" && action_name == "index"
    when :recipes
      controller_name == "recipes"
    when :strength
      controller_name == "workout_plans" || controller_name == "strength_sessions"
    when :outfits
      controller_name == "outfit_photos" || controller_name == "progress_photos"
    when :goals
      controller_name == "goals"
    else
      false
    end
  end

  def nav_item_class(key)
    [ "nav-link", ("active" if nav_active?(key)) ].compact.join(" ")
  end

  def mobile_tab_class(key)
    [ "mobile-tab", ("active" if nav_active?(key)) ].compact.join(" ")
  end

  def body_target_badges(labels, extra_class: "")
    labels = Array(labels).map(&:to_s).reject(&:blank?)
    return "" if labels.empty?

    safe_join(labels.map { |label|
      content_tag(:span, label, class: [ "badge", "text-bg-light", "text-dark", "border", "me-1", "mb-1", extra_class ].compact)
    })
  end
end
