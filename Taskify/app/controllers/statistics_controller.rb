class StatisticsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Cache statistics data for better performance
    cache_key = "user_statistics_#{current_user.id}_#{current_user.tasks.maximum(:updated_at)&.to_i}"

    @statistics_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      calculate_statistics_data
    end

    # Extract cached data
    @total_tasks = @statistics_data[:total_tasks]
    @completed_tasks = @statistics_data[:completed_tasks]
    @pending_tasks = @statistics_data[:pending_tasks]
    @overdue_tasks = @statistics_data[:overdue_tasks]
    @completion_percentage = @statistics_data[:completion_percentage]
    @weekly_completed_data = @statistics_data[:weekly_completed_data]
    @weekly_overdue_data = @statistics_data[:weekly_overdue_data]

    # Chart data for main stats
    @completed_chart_data = {
      labels: [ "Week 1", "Week 2", "Week 3", "Week 4" ],
      datasets: [ {
        label: "Tasks Completed",
        data: @weekly_completed_data,
        backgroundColor: "#3b82f6",
        borderColor: "#2563eb",
        borderWidth: 1,
        borderRadius: 4
      } ]
    }

    @overdue_chart_data = {
      labels: [ "Week 1", "Week 2", "Week 3", "Week 4" ],
      datasets: [ {
        label: "Tasks Overdue",
        data: @weekly_overdue_data,
        borderColor: "#ef4444",
        backgroundColor: "rgba(239, 68, 68, 0.1)",
        borderWidth: 2,
        fill: true,
        tension: 0.4
      } ]
    }
  end

  private

  def calculate_statistics_data
    # Get basic counts with a single query
    task_counts = current_user.tasks.group(:status).count
    total_tasks = task_counts.values.sum
    completed_tasks = task_counts["completed"] || 0
    pending_tasks = task_counts["pending"] || 0

    # Calculate overdue tasks efficiently
    overdue_tasks = current_user.tasks.where("due_date < ? AND status = ?", Time.current, "pending").count

    # Calculate completion percentage
    completion_percentage = total_tasks > 0 ? ((completed_tasks.to_f / total_tasks) * 100).round(1) : 0.0

    # Calculate weekly data more efficiently
    weekly_completed_data = calculate_weekly_data("completed")
    weekly_overdue_data = calculate_weekly_data("overdue")

    {
      total_tasks: total_tasks,
      completed_tasks: completed_tasks,
      pending_tasks: pending_tasks,
      overdue_tasks: overdue_tasks,
      completion_percentage: completion_percentage,
      weekly_completed_data: weekly_completed_data,
      weekly_overdue_data: weekly_overdue_data
    }
  end

  def calculate_weekly_data(type)
    # Use a single query to get all weekly data at once
    case type
    when "completed"
      # Get completed tasks grouped by week
      weeks_data = []
      4.times do |i|
        week_start = (3 - i).weeks.ago.beginning_of_week
        week_end = week_start.end_of_week

        count = current_user.tasks
          .where(status: :completed)
          .where(updated_at: week_start..week_end)
          .count

        weeks_data << count
      end
      weeks_data
    when "overdue"
      # Get overdue tasks grouped by week
      weeks_data = []
      4.times do |i|
        week_start = (3 - i).weeks.ago.beginning_of_week
        week_end = week_start.end_of_week

        # Count tasks that became overdue during this week
        count = current_user.tasks
          .where(status: :pending)
          .where(due_date: week_start..week_end)
          .where("due_date < ?", week_end)
          .count

        weeks_data << count
      end
      weeks_data
    end
  end
end
