class Task < ApplicationRecord
  # Include concerns para funcionalidades modulares
  include Categorizable
  include Notifiable
  include Auditable
  include TimeFormattable

  # Configuración de auditoría - especificar qué atributos auditar
  audit_attributes :title, :description, :status, :priority, :due_date, :assignee_id, :category

  # Include Kaminari pagination
  paginates_per 10

  belongs_to :user
  belongs_to :assignee, class_name: "User", optional: true

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 200 }
  validates :status, presence: true
  validates :priority, presence: true

  enum :status, { pending: "pending", completed: "completed" }
  enum :priority, { low: 0, medium: 1, high: 2 }, default: :medium

  # Optimized scopes with proper indexing
  scope :pending_tasks, -> { where(status: :pending).order(created_at: :desc) }
  scope :due_soon, -> { where("due_date <= ?", 24.hours.from_now).where(status: :pending) }

  # Improved search scope with fallback for compatibility
  scope :search, ->(query) {
    return all if query.blank?

    sanitized_query = query.strip
    return all if sanitized_query.blank?

    # Use ILIKE for simple contains search - more user-friendly
    where("title ILIKE ? OR description ILIKE ? OR category ILIKE ?",
          "%#{sanitized_query}%", "%#{sanitized_query}%", "%#{sanitized_query}%")
      .order(:title)
  }

  # Role-based visibility scopes
  scope :visible_to_user, ->(user) {
    case user.role
    when "admin"
      all # Admins can see all tasks
    when "task_maker"
      where("user_id = ? OR assignee_id = ?", user.id, user.id) # Own tasks + assigned to them
    when "task_doer"
      where(assignee_id: user.id) # Only tasks assigned to them
    else
      none
    end
  }

  scope :assigned_to, ->(user) { where(assignee_id: user.id) }
  scope :created_by, ->(user) { where(user_id: user.id) }
  scope :unassigned, -> { where(assignee_id: nil) }

  def completed?
    status == "completed"
  end

  def due_soon?
    due_date.present? && due_date <= 24.hours.from_now && pending?
  end

  def overdue?
    due_date.present? && due_date.to_date < Date.current && pending?
  end

  def days_until_due
    return nil unless due_date.present?
    ((due_date.to_date - Date.current).to_i)
  end

  def due_status_es
    return nil unless due_date.present?

    # Cache the calculation to avoid repeated date operations
    @due_status_es ||= calculate_due_status_es
  end

  def priority_color
    # Use a hash for O(1) lookup instead of case statement
    @priority_colors ||= {
      "low" => "#10b981",    # green
      "medium" => "#f59e0b", # yellow/orange
      "high" => "#ef4444"    # red
    }
    @priority_colors[priority] || "#6b7280"
  end

  def priority_label_es
    # Use a hash for O(1) lookup
    @priority_labels ||= {
      "low" => "Baja",
      "medium" => "Media",
      "high" => "Alta"
    }
    @priority_labels[priority] || priority.capitalize
  end

  def assigned?
    assignee_id.present?
  end

  def assignee_name
    assignee&.name || "Sin asignar"
  end

  def creator_name
    user&.name || "Desconocido"
  end

  def can_be_viewed_by?(current_user)
    return false unless current_user

    case current_user.role
    when "admin"
      true
    when "task_maker"
      user_id == current_user.id || assignee_id == current_user.id
    when "task_doer"
      assignee_id == current_user.id
    else
      false
    end
  end

  def can_be_edited_by?(current_user)
    return false unless current_user

    case current_user.role
    when "admin"
      true
    when "task_maker"
      user_id == current_user.id
    else
      false
    end
  end

  # Class method for bulk operations
  def self.bulk_update_status(task_ids, status)
    where(id: task_ids).update_all(status: status, updated_at: Time.current)
  end

  private

  def calculate_due_status_es
    if overdue?
      days_overdue = (Date.current - due_date.to_date).to_i
      "Vencida hace #{days_overdue} #{ days_overdue == 1 ? 'día' : 'días' }"
    else
      # For all non-overdue tasks with due dates, show the status
      days_left = days_until_due
      case days_left
      when 0
        "Vence hoy"
      when 1
        "Vence mañana"
      else
        "Vence en #{days_left} días"
      end
    end
  end
end
