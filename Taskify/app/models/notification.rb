class Notification < ApplicationRecord
  include TimeFormattable
  
  # Asociaciones
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  # Validaciones
  validates :notification_type, presence: true
  validates :message, presence: true, length: { maximum: 500 }
  validates :notification_type, inclusion: { 
    in: %w[task_assigned task_completed task_overdue task_due_soon task_updated task_deleted deadline_reminder weekly_summary],
    message: "debe ser un tipo de notificación válido"
  }

  # Callbacks
  before_validation :set_default_read_status, if: -> { read.nil? }
  after_create :broadcast_to_user, if: -> { user.real_time_notifications? }

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_type, ->(type) { where(notification_type: type) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }

  # Enums para facilidad de uso
  enum notification_type: {
    task_assigned: 'task_assigned',
    task_completed: 'task_completed',
    task_overdue: 'task_overdue', 
    task_due_soon: 'task_due_soon',
    task_updated: 'task_updated',
    task_deleted: 'task_deleted',
    deadline_reminder: 'deadline_reminder',
    weekly_summary: 'weekly_summary'
  }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end

  def mark_as_unread!
    update!(read: false, read_at: nil)
  end



  def priority_level
    case notification_type
    when 'task_overdue'
      'high'
    when 'task_due_soon', 'deadline_reminder'
      'medium'
    else
      'low'
    end
  end

  def icon_class
    case notification_type
    when 'task_assigned'
      'fas fa-user-plus'
    when 'task_completed'
      'fas fa-check-circle'
    when 'task_overdue'
      'fas fa-exclamation-triangle'
    when 'task_due_soon', 'deadline_reminder'
      'fas fa-clock'
    when 'task_updated'
      'fas fa-edit'
    when 'task_deleted'
      'fas fa-trash'
    when 'weekly_summary'
      'fas fa-chart-bar'
    else
      'fas fa-bell'
    end
  end

  def color_class
    case priority_level
    when 'high'
      'text-red-600'
    when 'medium'
      'text-yellow-600'
    else
      'text-blue-600'
    end
  end

  def self.cleanup_old_notifications(days: 30)
    where('created_at < ?', days.days.ago).destroy_all
  end

  def self.mark_all_as_read_for_user(user)
    where(user: user, read: false).update_all(read: true, read_at: Time.current)
  end

  def self.daily_summary_for_user(user, date: Date.current)
    where(user: user, created_at: date.beginning_of_day..date.end_of_day)
      .group(:notification_type)
      .count
  end

  private

  def set_default_read_status
    self.read = false
  end

  def broadcast_to_user
    ActionCable.server.broadcast(
      "notifications_#{user_id}",
      {
        id: id,
        type: notification_type,
        message: message,
        icon: icon_class,
        color: color_class,
        time_ago: time_ago_in_words_es,
        data: data,
        created_at: created_at.iso8601
      }
    )
  end
end 