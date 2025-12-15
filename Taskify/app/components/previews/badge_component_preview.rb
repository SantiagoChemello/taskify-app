class BadgeComponentPreview < ViewComponent::Preview
  # @display bg_color "#f8fafc"
  def default
    render(BadgeComponent.new(text: "Default"))
  end

  # @param text text "Badge Text"
  # @param variant select [default, priority_high, priority_medium, priority_low, status_completed, status_pending, overdue, due_today, due_soon, category, role_admin, role_task_maker, role_task_doer]
  # @param size select [xs, sm, md, lg]
  def playground(text: "Badge", variant: :default, size: :sm)
    render(BadgeComponent.new(text: text, variant: variant.to_sym, size: size.to_sym))
  end

  def priority_badges
    render_with_template
  end

  def status_badges
    render_with_template
  end

  def role_badges
    render_with_template
  end

  def all_sizes
    render_with_template
  end

  private

  def render_with_template
    render_with_template_content
  end
end 