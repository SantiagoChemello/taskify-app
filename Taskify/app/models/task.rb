class Task < ApplicationRecord
  # Include Kaminari pagination
  paginates_per 10

  belongs_to :user

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 200 }
  validates :status, presence: true
  validates :priority, presence: true
  validates :category, length: { maximum: 30 }, allow_blank: true

  enum :status, { pending: 'pending', completed: 'completed' }
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
  
  # Add scope for efficient category queries
  scope :with_category, ->(category) { where(category: category) }
  scope :without_category, -> { where(category: [nil, '']) }

  def completed?
    status == 'completed'
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
      'low' => '#3b82f6',    # blue
      'medium' => '#f59e0b', # yellow/orange
      'high' => '#ef4444'    # red
    }
    @priority_colors[priority] || '#6b7280'
  end

  def priority_label_es
    # Use a hash for O(1) lookup
    @priority_labels ||= {
      'low' => 'Baja',
      'medium' => '- Media',
      'high' => 'Alta'
    }
    @priority_labels[priority] || priority.capitalize
  end

  def category_label_es
    return 'Sin categoría' if category.blank?
    category.capitalize
  end

  def category_color
    return '#6b7280' if category.blank?  # gray for no category
    
    # Cache category colors to avoid repeated calculations
    @category_color ||= calculate_category_color
  end

  def created_at_relative_es
    # Cache the relative time calculation
    @created_at_relative_es ||= calculate_relative_time
  end

  def self.all_categories_for_user(user)
    # Use Rails cache for better performance
    Rails.cache.fetch("user_categories_#{user.id}", expires_in: 1.hour) do
      user.tasks.where.not(category: [nil, '']).distinct.pluck(:category).sort
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

  def calculate_category_color
    # Predefined colors for common categories
    predefined_colors = {
      'trabajo' => '#3b82f6',    # blue
      'personal' => '#8b5cf6',   # purple
      'estudios' => '#10b981',   # green
      'hogar' => '#f59e0b',      # orange
      'casa' => '#f59e0b',       # orange
      'salud' => '#ef4444',      # red
      'finanzas' => '#059669',   # emerald
      'dinero' => '#059669',     # emerald
      'ejercicio' => '#dc2626',  # red
      'deporte' => '#dc2626',    # red
      'ocio' => '#7c3aed',       # violet
      'entretenimiento' => '#7c3aed' # violet
    }
    
    predefined_colors[category.downcase] || generate_category_color(category)
  end

  def calculate_relative_time
    time_diff = Time.current - created_at
    
    case time_diff
    when 0..59
      'hace unos segundos'
    when 60..3599
      minutes = (time_diff / 60).to_i
      "hace #{minutes} #{ minutes == 1 ? 'minuto' : 'minutos' }"
    when 3600..86399
      hours = (time_diff / 3600).to_i
      "hace #{hours} #{ hours == 1 ? 'hora' : 'horas' }"
    when 86400..604799
      days = (time_diff / 86400).to_i
      "hace #{days} #{ days == 1 ? 'día' : 'días' }"
    else
      created_at.strftime("%d/%m/%Y")
    end
  end

  def generate_category_color(category_name)
    # Generate a consistent color based on the category name hash
    colors = ['#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444', '#059669', '#dc2626', '#7c3aed', '#0891b2', '#c026d3']
    hash = category_name.sum(&:ord)
    colors[hash % colors.length]
  end
end
