require "test_helper"

class PunditTestRecordPolicyTest < ActiveSupport::TestCase
  test "authorize returns the record for its owner" do
    record = PunditTestRecord.new(users(:one))

    assert_equal record, Pundit.authorize(users(:one), record, :show?)
  end

  test "authorize raises for another user's record" do
    record = PunditTestRecord.new(users(:one))

    error = assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(users(:two), record, :show?)
    end

    assert_equal :show?, error.query
    assert_equal record, error.record
  end

  test "policy scope resolves to the user's records" do
    assert_equal [ users(:one) ], Pundit.policy_scope!(users(:one), PunditTestRecord).map(&:user)
  end
end
