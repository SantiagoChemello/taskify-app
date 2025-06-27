module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :notifiable, dependent: :destroy
    has_many :user_notifications, through: :notifications
    
    # Callbacks para notificaciones automáticas
    after_create :send_creation_notification
    after_update :send_update_notification, if: :should_notify_on_update?
    before_destroy :send_deletion_notification
  end

  # Tipos de notificaciones
  NOTIFICATION_TYPES = {
    task_assigned: 'task_assigned',
    task_completed: 'task_completed', 
    task_overdue: 'task_overdue',
    task_due_soon: 'task_due_soon',
    task_updated: 'task_updated',
    task_deleted: 'task_deleted',
    deadline_reminder: 'deadline_reminder',
    weekly_summary: 'weekly_summary'
  }.freeze

  def notify_users(users, notification_type, message: nil, data: {})
    Array(users).each do |user|
      next unless user.should_receive_notification?(notification_type)
      
      create_notification_for_user(
        user: user,
        notification_type: notification_type,
        message: message || default_message_for(notification_type),
        data: data.merge(default_notification_data)
      )
    end
  end

  def notify_assignee(notification_type, custom_message: nil)
    return unless assignee.present?
    
    notify_users(
      assignee, 
      notification_type,
      message: custom_message,
      data: { task_id: id, task_title: title }
    )
  end

  def notify_creator(notification_type, custom_message: nil)
    return unless user.present?
    
    notify_users(
      user,
      notification_type, 
      message: custom_message,
      data: { task_id: id, task_title: title }
    )
  end

  def broadcast_to_team(notification_type, custom_message: nil)
    team_users = [user, assignee].compact.uniq
    notify_users(team_users, notification_type, message: custom_message)
  end

  private

  def send_creation_notification
    if assignee.present?
      notify_assignee(:task_assigned, 
        custom_message: "Se te ha asignado la tarea: #{title}")
    end
  end

  def send_update_notification
    changes_to_notify = notification_worthy_changes
    return if changes_to_notify.empty?

    if assignee_id_changed? && assignee.present?
      notify_assignee(:task_assigned,
        custom_message: "Se te ha asignado una tarea actualizada: #{title}")
    end

    if changes_to_notify.include?('due_date') && assignee.present?
      notify_assignee(:task_updated,
        custom_message: "La fecha límite de tu tarea '#{title}' ha cambiado")
    end
  end

  def send_deletion_notification
    if assignee.present?
      notify_assignee(:task_deleted,
        custom_message: "La tarea '#{title}' ha sido eliminada")
    end
  end

  def should_notify_on_update?
    notification_worthy_changes.any?
  end

  def notification_worthy_changes
    saved_changes.keys & %w[assignee_id due_date status priority]
  end

  def default_message_for(notification_type)
    case notification_type
    when :task_assigned
      "Nueva tarea asignada: #{title}"
    when :task_completed
      "Tarea completada: #{title}"
    when :task_overdue
      "Tarea vencida: #{title}"
    when :task_due_soon
      "Tarea próxima a vencer: #{title}"
    when :deadline_reminder
      "Recordatorio: #{title} vence en #{time_until_due}"
    else
      "Actualización en tarea: #{title}"
    end
  end

  def default_notification_data
    {
      notifiable_type: self.class.name,
      notifiable_id: id,
      created_at: Time.current
    }
  end

  def create_notification_for_user(user:, notification_type:, message:, data:)
    notification = Notification.create!(
      user: user,
      notifiable: self,
      notification_type: notification_type,
      message: message,
      data: data,
      read: false
    )

    # Enviar notificación en tiempo real
    broadcast_notification(notification) if user.real_time_notifications?
    
    # Enviar email si está habilitado
    send_email_notification(notification) if user.email_notifications?
    
    notification
  end

  def broadcast_notification(notification)
    ActionCable.server.broadcast(
      "notifications_#{notification.user_id}",
      {
        id: notification.id,
        type: notification.notification_type,
        message: notification.message,
        data: notification.data,
        created_at: notification.created_at.iso8601
      }
    )
  end

  def send_email_notification(notification)
    NotificationMailer.task_notification(notification).deliver_later
  end
end 