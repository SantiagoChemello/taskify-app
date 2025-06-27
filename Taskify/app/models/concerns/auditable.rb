module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable, dependent: :destroy
    
    # Callbacks para auditoría automática
    after_create :log_creation
    after_update :log_updates
    after_destroy :log_deletion
    
    # Atributos a auditar por defecto
    class_attribute :audited_attributes, default: []
    class_attribute :audit_user_method, default: :current_user
  end

  def audit_changes(user: nil, action: nil, details: {})
    user ||= try(audit_user_method)
    
    audit_logs.create!(
      user: user,
      action: action || infer_action,
      changes_data: format_changes_for_audit,
      details: details,
      ip_address: try(:request)&.remote_ip,
      user_agent: try(:request)&.user_agent,
      performed_at: Time.current
    )
  end

  def audit_history(limit: 50)
    audit_logs.includes(:user)
              .order(performed_at: :desc)
              .limit(limit)
  end

  def changes_since(timestamp)
    audit_logs.where('performed_at > ?', timestamp)
              .order(:performed_at)
  end

  def who_changed_what(attribute)
    audit_logs.where("changes_data ? ?", attribute.to_s)
              .includes(:user)
              .order(:performed_at)
  end

  def last_modified_by
    audit_logs.where(action: ['update', 'create'])
              .order(:performed_at)
              .last
              &.user
  end

  def change_summary
    {
      total_changes: audit_logs.count,
      last_change: audit_logs.maximum(:performed_at),
      change_frequency: calculate_change_frequency,
      most_active_user: most_active_user_on_record
    }
  end

  private

  def log_creation
    audit_changes(
      action: 'create',
      details: { 
        message: "#{self.class.name} creado",
        initial_attributes: auditable_attributes
      }
    )
  end

  def log_updates
    return unless has_auditable_changes?
    
    audit_changes(
      action: 'update',
      details: {
        message: "#{self.class.name} actualizado",
        changed_attributes: changed_auditable_attributes
      }
    )
  end

  def log_deletion
    audit_changes(
      action: 'delete',
      details: {
        message: "#{self.class.name} eliminado",
        final_attributes: auditable_attributes
      }
    )
  end

  def has_auditable_changes?
    return true if audited_attributes.empty? # Auditar todo si no se especifica

    (saved_changes.keys & audited_attributes.map(&:to_s)).any?
  end

  def changed_auditable_attributes
    if audited_attributes.empty?
      saved_changes
    else
      saved_changes.slice(*audited_attributes.map(&:to_s))
    end
  end

  def auditable_attributes
    if audited_attributes.empty?
      attributes
    else
      attributes.slice(*audited_attributes.map(&:to_s))
    end
  end

  def format_changes_for_audit
    changes_to_audit = changed_auditable_attributes
    
    changes_to_audit.transform_values do |change|
      {
        from: format_value_for_audit(change[0]),
        to: format_value_for_audit(change[1])
      }
    end
  end

  def format_value_for_audit(value)
    case value
    when ActiveRecord::Base
      { id: value.id, type: value.class.name, display: value.to_s }
    when Time, DateTime, Date
      value.iso8601
    else
      value
    end
  end

  def infer_action
    if destroyed?
      'delete'
    elsif persisted? && saved_changes.any?
      'update'
    elsif persisted?
      'create'
    else
      'unknown'
    end
  end

  def calculate_change_frequency
    return 0 if audit_logs.count < 2
    
    time_span = audit_logs.maximum(:performed_at) - audit_logs.minimum(:performed_at)
    return 0 if time_span <= 0
    
    (audit_logs.count.to_f / time_span.to_f * 1.day).round(2)
  end

  def most_active_user_on_record
    audit_logs.group(:user_id)
              .count
              .max_by { |_, count| count }
              &.first
  end

  # Métodos de clase
  class_methods do
    def audit_attributes(*attributes)
      self.audited_attributes = attributes.map(&:to_s)
    end

    def set_audit_user_method(method_name)
      self.audit_user_method = method_name
    end

    def recent_activity(days: 7)
      joins(:audit_logs)
        .where(audit_logs: { performed_at: days.days.ago.. })
        .distinct
    end

    def most_active_records(limit: 10)
      joins(:audit_logs)
        .group("#{table_name}.id")
        .order('COUNT(audit_logs.id) DESC')
        .limit(limit)
    end
  end
end 