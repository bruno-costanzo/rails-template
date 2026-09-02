require "test_helper"

class UserTest < ActiveSupport::TestCase
  include MessageQuotaHelper

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

  test "processes a thumb avatar variant with the vips processor" do
    user = users(:one)
    user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")

    variant = user.avatar.variant(:thumb).processed
    image = Vips::Image.new_from_buffer(variant.download, "")

    assert_equal 48, image.width
    assert_equal 48, image.height
  end

  test "the daily quota counts only today's own messages" do
    user = users(:one)
    chat = user.chats.create!(model: "gpt-4o-mini")
    seed_messages(chat, 3)
    seed_messages(chat, 2, role: "assistant")
    seed_messages(chat, 4, created_at: 1.day.ago)

    assert_equal User::DAILY_MESSAGE_LIMIT - 3, user.messages_remaining_today
  end

  test "the daily quota counts every chat, support included" do
    user = users(:one)
    seed_messages(user.chats.create!(model: "gpt-4o-mini"), 2)
    seed_messages(user.chats.create!(support: true), 3)

    assert_equal User::DAILY_MESSAGE_LIMIT - 5, user.messages_remaining_today
  end

  test "the daily quota never goes negative" do
    user = users(:one)
    seed_messages(user.chats.create!(model: "gpt-4o-mini"), User::DAILY_MESSAGE_LIMIT + 1)

    assert_equal 0, user.messages_remaining_today
  end
end
