require "test_helper"

class ChatClosingTest < ActiveSupport::TestCase
  test "a support conversation with no activity for the inactivity window is closed" do
    chat = support_chat_last_active((Chat::INACTIVITY_WINDOW + 1.hour).ago)

    Chat.close_inactive_support_conversations

    assert chat.reload.closed?
  end

  test "a support conversation that is still active stays open" do
    chat = support_chat_last_active(1.hour.ago)

    Chat.close_inactive_support_conversations

    assert_not chat.reload.closed?
  end

  test "an idle conversation with no messages at all is closed on its own age" do
    chat = users(:one).chats.create!(support: true, created_at: (Chat::INACTIVITY_WINDOW + 1.hour).ago)

    Chat.close_inactive_support_conversations

    assert chat.reload.closed?
  end

  test "ordinary chats are never closed by inactivity" do
    chat = users(:one).chats.create!(support: false, created_at: 3.days.ago)

    Chat.close_inactive_support_conversations

    assert_not chat.reload.closed?
  end

  test "closing is idempotent and keeps the original moment" do
    chat = support_chat_last_active(2.days.ago)
    chat.close!
    closed_at = chat.reload.closed_at

    chat.close!

    assert_equal closed_at, chat.reload.closed_at
  end

  test "resolving the ticket closes the conversation it came from" do
    chat = support_chat_last_active(1.minute.ago)
    feedback = users(:one).feedbacks.create!(message: "No puedo entrar", chat: chat)

    feedback.resolve!

    assert chat.reload.closed?
  end

  test "resolving a ticket that came from no conversation is harmless" do
    feedback = users(:one).feedbacks.create!(message: "Vine del formulario")

    feedback.resolve!

    assert feedback.reload.resolved?
  end

  private

  def support_chat_last_active(moment)
    users(:one).chats.create!(support: true, created_at: moment).tap do |chat|
      chat.messages.create!(role: :user, content: "Hola", created_at: moment)
    end
  end
end
