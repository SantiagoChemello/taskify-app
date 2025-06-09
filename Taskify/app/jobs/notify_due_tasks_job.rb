class NotifyDueTasksJob < ApplicationJob
  queue_as :default

  def perform
    # Find all tasks that are due soon
    due_tasks = Task.due_soon.includes(:user)
    
    return if due_tasks.empty?
    
    # Group tasks by user for efficient processing
    due_tasks.group_by(&:user).each do |user, tasks|
      notify_user_about_due_tasks(user, tasks)
    end
    
    Rails.logger.info "NotifyDueTasksJob completed. Processed #{due_tasks.count} due tasks for #{due_tasks.group_by(&:user).count} users."
  end

  private

  def notify_user_about_due_tasks(user, tasks)
    # For now, we'll log the notifications
    # In a real app, this could send emails, push notifications, etc.
    
    overdue_tasks = tasks.select(&:overdue?)
    due_today_tasks = tasks.select { |t| t.days_until_due == 0 && !t.overdue? }
    due_soon_tasks = tasks.select { |t| t.due_soon? && t.days_until_due > 0 }
    
    if overdue_tasks.any?
      Rails.logger.warn "User #{user.email} has #{overdue_tasks.count} overdue tasks: #{overdue_tasks.map(&:title).join(', ')}"
    end
    
    if due_today_tasks.any?
      Rails.logger.info "User #{user.email} has #{due_today_tasks.count} tasks due today: #{due_today_tasks.map(&:title).join(', ')}"
    end
    
    if due_soon_tasks.any?
      Rails.logger.info "User #{user.email} has #{due_soon_tasks.count} tasks due soon: #{due_soon_tasks.map(&:title).join(', ')}"
    end
  end
end
