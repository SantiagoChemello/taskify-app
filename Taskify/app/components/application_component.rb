class ApplicationComponent < ViewComponent::Base
  # Base component class for all ViewComponents in the application

  private

  # Helper method for generating Tailwind CSS classes
  def cn(*classes)
    classes.compact.join(" ")
  end

  # Helper method for conditional classes
  def conditional_class(condition, true_class, false_class = nil)
    condition ? true_class : false_class
  end
end
