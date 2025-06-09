class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get basic stats
    @total_tasks = current_user.tasks.count
    @completed_tasks = current_user.tasks.where(status: 'completed').count
    @pending_tasks = current_user.tasks.where(status: 'pending').count
    @completion_rate = @total_tasks > 0 ? ((@completed_tasks.to_f / @total_tasks) * 100).round(1) : 0
    
    # Get time-based stats
    current_time = Time.current
    today_start = current_time.beginning_of_day
    today_end = current_time.end_of_day
    week_start = current_time.beginning_of_week
    
    @tasks_today = current_user.tasks.where(created_at: today_start..today_end).count
    @tasks_this_week = current_user.tasks.where(created_at: week_start..current_time).count
    @completed_today = current_user.tasks.where(status: 'completed', updated_at: today_start..today_end).count
    
    # Get notification data
    three_days_end = 3.days.from_now.end_of_day
    user_tasks = current_user.tasks.where(status: 'pending')
    @overdue_tasks = user_tasks.where('due_date < ?', current_time).count
    @due_today_tasks = user_tasks.where(due_date: today_start..today_end).count
    @due_soon_tasks = user_tasks.where(due_date: today_end..three_days_end).count
    
    # Get latest tasks (recent activity)
    @recent_tasks = current_user.tasks.includes(:user)
                                     .order(updated_at: :desc)
                                     .limit(5)
    
    # Get upcoming tasks
    @upcoming_tasks = current_user.tasks.where(status: 'pending')
                                       .where('due_date >= ?', current_time)
                                       .order(:due_date)
                                       .limit(5)
    
    # Get categories for quick stats
    @categories_stats = current_user.tasks.where.not(category: [nil, ''])
                                         .group(:category)
                                         .group(:status)
                                         .count
  end
end 