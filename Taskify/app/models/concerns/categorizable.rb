module Categorizable
  extend ActiveSupport::Concern

  included do
    # Validaciones
    validates :category, length: { maximum: 50 }, allow_blank: true

    # Scopes útiles para categorías
    scope :with_category, ->(category) { where(category: category) }
    scope :without_category, -> { where(category: [ nil, "" ]) }
    scope :by_category, -> { order(:category) }
  end

  # Métodos de instancia
  def has_category?
    category.present?
  end

  def category_name
    category.presence || "Sin categor\u00EDa"
  end

  def category_label_es
    return "Sin categor\u00EDa" if category.blank?
    category.capitalize
  end

  def category_color
    return "#6b7280" if category.blank?  # gray for no category

    # Cache category colors to avoid repeated calculations
    @category_color ||= calculate_category_color
  end

  def set_category(category_name)
    self.category = category_name.present? ? category_name.strip.downcase : nil
  end

  def clear_category
    self.category = nil
  end

  private

  def calculate_category_color
    # Predefined colors for common categories
    predefined_colors = {
      "trabajo" => "#3b82f6",    # blue
      "personal" => "#8b5cf6",   # purple
      "estudios" => "#10b981",   # green
      "hogar" => "#f59e0b",      # orange
      "casa" => "#f59e0b",       # orange
      "salud" => "#ef4444",      # red
      "finanzas" => "#059669",   # emerald
      "dinero" => "#059669",     # emerald
      "ejercicio" => "#dc2626",  # red
      "deporte" => "#dc2626",    # red
      "ocio" => "#7c3aed",       # violet
      "entretenimiento" => "#7c3aed" # violet
    }

    predefined_colors[category.downcase] || generate_category_color(category)
  end

  def generate_category_color(category_name)
    # Generate a consistent color based on the category name hash
    colors = [ "#3b82f6", "#8b5cf6", "#10b981", "#f59e0b", "#ef4444", "#059669", "#dc2626", "#7c3aed", "#0891b2", "#c026d3" ]
    hash = category_name.sum(&:ord)
    colors[hash % colors.length]
  end

  # Métodos de clase
  class_methods do
    def all_categories_for_user(user)
      # Use Rails cache for better performance
      Rails.cache.fetch("user_categories_#{user.id}", expires_in: 1.hour) do
        user.tasks.where.not(category: [ nil, "" ]).distinct.pluck(:category).sort
      end
    end

    def popular_categories(limit: 10)
      where.not(category: [ nil, "" ])
           .group(:category)
           .order("COUNT(*) DESC")
           .limit(limit)
           .pluck(:category)
    end

    def categories_for_user(user)
      case user.role
      when "admin"
        where.not(category: [ nil, "" ]).distinct.pluck(:category).sort
      when "task_maker"
        where(user: user).where.not(category: [ nil, "" ]).distinct.pluck(:category).sort
      else
        where(assignee: user).where.not(category: [ nil, "" ]).distinct.pluck(:category).sort
      end
    end
  end
end
