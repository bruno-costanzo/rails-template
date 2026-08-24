require "test_helper"

class DocumentPolicyTest < ActiveSupport::TestCase
  test "authorize returns the record for its owner" do
    assert_equal documents(:one), Pundit.authorize(users(:one), documents(:one), :show?)
  end

  test "authorize raises for another user's document" do
    error = assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(users(:two), documents(:one), :show?)
    end

    assert_equal :show?, error.query
    assert_equal documents(:one), error.record
  end

  test "policy scope resolves to the user's documents" do
    assert_equal [ documents(:one) ], Pundit.policy_scope!(users(:one), Document).to_a
  end
end
