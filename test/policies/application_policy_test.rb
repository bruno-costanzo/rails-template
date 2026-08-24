require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @record = PunditTestRecord.new(@user)
    @policy = ApplicationPolicy.new(@user, @record)
  end

  test "exposes user and record" do
    assert_equal @user, @policy.user
    assert_equal @record, @policy.record
  end

  test "denies every action by default" do
    assert_not @policy.index?
    assert_not @policy.show?
    assert_not @policy.create?
    assert_not @policy.new?
    assert_not @policy.update?
    assert_not @policy.edit?
    assert_not @policy.destroy?
  end

  test "scope requires resolve to be defined" do
    scope = ApplicationPolicy::Scope.new(@user, PunditTestRecord)
    error = assert_raises(NoMethodError) { scope.resolve }
    assert_match "You must define #resolve", error.message
  end
end
