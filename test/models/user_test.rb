require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a name" do
    user = User.new(name: "", email_address: "new@example.com", password: "password")
    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
