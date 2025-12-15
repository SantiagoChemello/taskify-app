class BadgeComponent < ApplicationComponent
  def initialize(
    text:,
    variant: :default,
    size: :sm,
    additional_classes: nil
  )
    @text = text
    @variant = variant
    @size = size
    @additional_classes = additional_classes
  end

  private

  attr_reader :text, :variant, :size, :additional_classes

  def badge_classes
    base_classes = "inline-flex items-center font-medium rounded-md"
    
    variant_classes = case variant
                     when :priority_high
                       "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
                     when :priority_medium
                       "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300"
                     when :priority_low
                       "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
                     when :status_completed
                       "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
                     when :status_pending
                       "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                     when :overdue
                       "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300 animate-pulse"
                     when :due_today
                       "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300"
                     when :due_soon
                       "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                     when :category
                       "bg-neutral-100 text-neutral-800 dark:bg-neutral-800 dark:text-neutral-300"
                     when :role_admin
                       "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300"
                     when :role_task_maker
                       "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                     when :role_task_doer
                       "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
                     else
                       "bg-neutral-100 text-neutral-800 dark:bg-neutral-800 dark:text-neutral-300"
                     end

    size_classes = case size
                  when :xs
                    "px-2 py-0.5 text-xs"
                  when :sm
                    "px-2.5 py-0.5 text-xs"
                  when :md
                    "px-3 py-1 text-sm"
                  when :lg
                    "px-4 py-1.5 text-sm"
                  else
                    "px-2.5 py-0.5 text-xs"
                  end

    [base_classes, variant_classes, size_classes, additional_classes].compact.join(" ")
  end
end 