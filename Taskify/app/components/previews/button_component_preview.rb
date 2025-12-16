class ButtonComponentPreview < ViewComponent::Preview
  # @display bg_color "#f8fafc"
  # @display viewport_width "800px"
  def default
    render(ButtonComponent.new) { "Button" }
  end

  # @param variant select [primary, secondary, danger, ghost, success]
  # @param size select [sm, md, lg, xl]
  # @param disabled toggle
  # @param full_width toggle
  def playground(variant: :primary, size: :md, disabled: false, full_width: false)
    render(ButtonComponent.new(variant: variant.to_sym, size: size.to_sym, disabled: disabled, full_width: full_width)) do
      "#{variant.to_s.humanize} Button"
    end
  end

  def all_variants
    render_with_template
  end

  def all_sizes
    render_with_template
  end

  def with_icons
    render_with_template
  end

  private

  def render_with_template
    render_with_template_content
  end
end
