class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role-based authorization
  enum :role, { admin: 0, task_maker: 1, task_doer: 2 }, default: :task_doer

  # Relationships
  has_many :tasks, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true

  # Role helper methods
  def admin?
    role == "admin"
  end

  def task_maker?
    role == "task_maker"
  end

  def task_doer?
    role == "task_doer"
  end

  def can_create_tasks?
    admin? || task_maker?
  end

  def can_assign_tasks?
    admin? || task_maker?
  end

  def full_name
    name
  end

  def role_label
    case role
    when "admin"
      "Administrador"
    when "task_maker"
      "Creador de Tareas"
    when "task_doer"
      "Ejecutor de Tareas"
    else
      role.humanize
    end
  end

  # Notification preferences - default to true for now
  def real_time_notifications?
    true
  end

  def email_notifications?
    true
  end

  def should_receive_notification?(notification_type)
    true # For now, all users receive all notifications
  end
end
