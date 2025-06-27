class DashboardPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  class Scope < Scope
    def resolve
      # Dashboard shows user-specific data, no scoping needed
      scope
    end
  end
end 