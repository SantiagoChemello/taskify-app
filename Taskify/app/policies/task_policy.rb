class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?
    record.can_be_viewed_by?(user)
  end

  def create?
    user&.can_create_tasks?
  end

  def update?
    return false unless user.present?
    record.can_be_edited_by?(user)
  end

  def destroy?
    return false unless user.present?
    record.can_be_edited_by?(user)
  end

  def assign?
    return false unless user.present?

    case user.role
    when "admin"
      true
    when "task_maker"
      # For new tasks, task_makers can assign (they will own it)
      # For existing tasks, only if they own it
      record.new_record? || record.user_id == user.id
    else
      false
    end
  end

  def complete?
    return false unless user.present?

    case user.role
    when "admin"
      true
    when "task_maker"
      record.user_id == user.id || record.assignee_id == user.id
    when "task_doer"
      record.assignee_id == user.id
    else
      false
    end
  end

  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      scope.visible_to_user(user)
    end
  end

  private

  def owned_by_user?
    record.user_id == user.id
  end

  def assigned_to_user?
    record.assignee_id == user.id
  end
end
