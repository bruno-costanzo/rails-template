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

  test "initials come from the first two name words" do
    assert_equal "AL", users(:one).initials
  end

  test "accepts a png avatar" do
    user = users(:one)
    user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")
    assert user.valid?
  end

  test "rejects a non-image avatar" do
    user = users(:one)
    user.avatar.attach(io: StringIO.new("plain text"), filename: "notes.txt", content_type: "text/plain")
    assert_not user.valid?
  end
end
