module ApplicationHelper
  def time_of_day_greeting(now = Time.current)
    case now.hour
    when 5..11 then "Good morning"
    when 12..17 then "Good afternoon"
    when 18..21 then "Good evening"
    else "Still up"
    end
  end

  def home_greeting(goal, now = Time.current)
    [ time_of_day_greeting(now), goal&.greeting_name ].compact_blank.join(", ")
  end

  def meal_type_label(meal_type)
    { "beverage" => "Beverage" }.fetch(meal_type.to_s, meal_type.to_s.humanize)
  end

  # Shared entry point for Open Food Facts search / barcode add.
  def add_product_link(return_to: nil, label: "Add product", css_class: "btn btn-primary")
    path = new_product_path(return_to: return_to.presence || request.fullpath)
    link_to path, class: css_class do
      safe_join([ tag.i(class: "bi bi-plus-lg me-1", aria: { hidden: true }), label ])
    end
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

  # Deficit pace uses the same status symbols as calorie/weight, but the words
  # mean something different: below_target here is "ahead of the loss plan".
  def deficit_pace_badge(status)
    return tag.span("—", class: "text-muted") if status == :unknown

    labels = {
      on_target: [ "On pace", "success" ],
      above_target: [ "Behind pace", "warning" ],
      below_target: [ "Ahead of pace", "info" ]
    }
    label, css = labels.fetch(status)
    tag.span(label, class: "badge text-bg-#{css}")
  end

  def weight_vs_goal_label(goal, weight)
    if goal.life_stage_pregnancy?
      guide = goal.gestational_weight_guidance
      return "Add LMP/due date + pre-pregnancy weight in Goals" unless guide.ready?
      return "No weight logged" if weight.blank?

      gain = guide.current_gain_kg(weight)
      expected = guide.expected_lower_gain_kg
      "Gain #{gain} kg (lower-path ~#{expected} kg by week #{guide.gestational_week}) · IOM #{guide.band[:total_min_kg]}–#{guide.band[:total_max_kg]} kg total"
    else
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
  end

  def pregnancy_gain_badge(status)
    labels = {
      on_lower_path: [ "On lower path", "success" ],
      within_range: [ "In IOM range", "info" ],
      above_range: [ "Above IOM pace", "warning" ],
      below_lower_bound: [ "Below lower bound", "secondary" ],
      unknown: [ "—", "light" ]
    }
    label, css = labels.fetch(status.to_sym, [ status.to_s.humanize, "light" ])
    tag.span(label, class: "badge text-bg-#{css}")
  end

  def nav_active?(key)
    case key.to_sym
    when :home
      controller_name == "dashboard"
    when :today
      controller_name == "daily_logs" && action_name != "index"
    when :metrics
      controller_name == "metrics"
    when :log
      controller_name == "daily_logs" && action_name == "index"
    when :recipes
      controller_name == "recipes"
    when :strength
      controller_name == "workout_plans" || controller_name == "strength_sessions"
    when :outfits
      controller_name == "outfit_photos" || controller_name == "progress_photos"
    when :goals, :profile
      controller_name.in?(%w[goals journals])
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
