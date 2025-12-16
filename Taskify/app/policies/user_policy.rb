class UserPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    user&.admin? || record == user
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin? || record == user
  end

  def destroy?
    user&.admin? && record != user
  end

  def manage_roles?
    user&.admin?
  end

  def assign_tasks?
    user&.admin? || user&.task_maker?
  end

  def edit_profile?
    user&.admin? || record == user
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
