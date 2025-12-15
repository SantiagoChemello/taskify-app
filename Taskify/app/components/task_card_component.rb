class TaskCardComponent < ApplicationComponent
  def initialize(task:, current_user:, animate_delay: 0)
    @task = task
    @current_user = current_user
    @animate_delay = animate_delay
  end

  private

  attr_reader :task, :current_user, :animate_delay

  def priority_indicator_class
    case task.priority
    when 'high'
      "w-3 h-3 bg-red-500 dark:bg-red-400 rounded-full animate-pulse"
    when 'medium'
      "w-3 h-3 bg-yellow-500 dark:bg-yellow-400 rounded-full"
    when 'low'
      "w-3 h-3 bg-green-500 dark:bg-green-400 rounded-full"
    else
      "w-3 h-3 bg-neutral-300 dark:bg-neutral-600 rounded-full"
    end
  end

  def due_date_class
    return "text-neutral-500 dark:text-neutral-400" unless task.due_date

    if task.due_date < Date.current
      "text-red-600 dark:text-red-400 font-medium"
    elsif task.due_date == Date.current
      "text-yellow-600 dark:text-yellow-400 font-medium"
    elsif task.due_date <= 3.days.from_now
      "text-blue-600 dark:text-blue-400 font-medium"
    else
      "text-neutral-500 dark:text-neutral-400"
    end
  end

  def due_date_text
    return "No due date" unless task.due_date

    if task.due_date < Date.current
      "Overdue"
    elsif task.due_date == Date.current
      "Due today"
    elsif task.due_date == Date.tomorrow
      "Due tomorrow"
    else
      task.due_date.strftime("%b %d")
    end
  end

  def animation_style
    "animation-delay: #{animate_delay}s" if animate_delay > 0
  end

  def card_classes
    base_classes = "group bg-white dark:bg-neutral-800 rounded-xl border border-neutral-200 dark:border-neutral-700 p-6 hover:shadow-lg dark:hover:shadow-neutral-900/25 transition-all duration-200 hover:border-neutral-300 dark:hover:border-neutral-600"
    
    if task.completed?
      "#{base_classes} opacity-75"
    else
      base_classes
    end
  end

  def can_edit_task?
    TaskPolicy.new(current_user, task).update?
  end

  def can_complete_task?
    TaskPolicy.new(current_user, task).complete?
  end
end 