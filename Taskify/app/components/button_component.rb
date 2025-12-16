class ButtonComponent < ApplicationComponent
  def initialize(
    variant: :primary,
    size: :md,
    type: :button,
    disabled: false,
    full_width: false,
    additional_classes: nil,
    **attributes
  )
    @variant = variant
    @size = size
    @type = type
    @disabled = disabled
    @full_width = full_width
    @additional_classes = additional_classes
    @attributes = attributes
  end

  private

  attr_reader :variant, :size, :type, :disabled, :full_width, :additional_classes, :attributes

  def button_classes
    base_classes = "inline-flex items-center justify-center font-medium rounded-xl transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"

    variant_classes = case variant
    when :primary
                       "bg-blue-600 hover:bg-blue-700 text-white shadow-lg hover:shadow-xl focus:ring-blue-500 transform hover:scale-105"
    when :secondary
                       "bg-white dark:bg-neutral-800 border border-neutral-300 dark:border-neutral-700 text-neutral-900 dark:text-white hover:bg-neutral-50 dark:hover:bg-neutral-700 focus:ring-blue-500"
    when :danger
                       "bg-red-600 hover:bg-red-700 text-white shadow-lg hover:shadow-xl focus:ring-red-500 transform hover:scale-105"
    when :ghost
                       "text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white hover:bg-neutral-100 dark:hover:bg-neutral-800 focus:ring-blue-500"
    when :success
                       "bg-green-600 hover:bg-green-700 text-white shadow-lg hover:shadow-xl focus:ring-green-500 transform hover:scale-105"
    else
                       "bg-blue-600 hover:bg-blue-700 text-white shadow-lg hover:shadow-xl focus:ring-blue-500 transform hover:scale-105"
    end

    size_classes = case size
    when :sm
                    "px-3 py-1.5 text-sm"
    when :md
                    "px-4 py-2 text-sm"
    when :lg
                    "px-6 py-3 text-base"
    when :xl
                    "px-8 py-4 text-lg"
    else
                    "px-4 py-2 text-sm"
    end

    width_classes = full_width ? "w-full" : ""

    [ base_classes, variant_classes, size_classes, width_classes, additional_classes ].compact.join(" ")
  end

  def button_attributes
    base_attrs = {
      type: type,
      disabled: disabled,
      class: button_classes
    }

    base_attrs.merge(attributes)
  end
end
