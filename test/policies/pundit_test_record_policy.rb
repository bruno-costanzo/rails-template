class PunditTestRecordPolicy < ApplicationPolicy
  def show?
    record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all.select { |record| record.user == user }
    end
  end
end
