require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "broadcasts itself synchronously when created, before any later chunk appends" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")

    assert_broadcasts("chat_#{chat.id}", 1) do
      chat.messages.create!(role: :assistant, content: "Hello")
    end
  end

  test "broadcasts a replace synchronously when updated" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    message = chat.messages.create!(role: :assistant, content: "")

    assert_broadcasts("chat_#{chat.id}", 1) do
      message.update!(content: "Hello world")
    end
  end

  test "broadcasts a remove synchronously when destroyed" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    message = chat.messages.create!(role: :assistant, content: "Hello")

    assert_broadcasts("chat_#{chat.id}", 1) do
      message.destroy!
    end
  end

  test "does not broadcast technical tool-call details when a message updates in a support chat" do
    chat = users(:one).chats.create!(support: true)
    message = chat.messages.create!(role: :assistant, content: "")
    message.tool_calls.create!(tool_call_id: "call_1", name: "create_support_ticket", arguments: { title: "x", summary: "y" })

    clear_messages("chat_#{chat.id}")
    message.update!(updated_at: Time.current)
    broadcasted = broadcasts("chat_#{chat.id}")

    assert_equal 1, broadcasted.size
    assert_no_match "create_support_ticket", broadcasted.first
  end

  test "renders normally for a system message in a regular chat" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    message = chat.messages.create!(role: :system, content: "Be concise.")

    assert_equal "messages/system", message.to_partial_path
  end

  test "hides a system message from the person in a support chat" do
    chat = users(:one).chats.create!(support: true)
    message = chat.messages.create!(role: :system, content: "Never mention code.")

    assert_equal "messages/blank", message.to_partial_path
  end

  test "hides a tool result message from the person in a support chat" do
    chat = users(:one).chats.create!(support: true)
    message = chat.messages.create!(role: :tool, content: "Ticket filed.")

    assert_equal "messages/blank", message.to_partial_path
  end

  test "hides a tool call message from the person in a support chat" do
    chat = users(:one).chats.create!(support: true)
    message = chat.messages.create!(role: :assistant, content: "")
    message.tool_calls.create!(tool_call_id: "call_1", name: "create_support_ticket", arguments: { title: "x", summary: "y" })

    assert_equal "messages/blank", message.to_partial_path
  end

  test "shows a plain assistant reply to the person in a support chat" do
    chat = users(:one).chats.create!(support: true)
    message = chat.messages.create!(role: :assistant, content: "Thanks, I've filed this for the team.")

    assert_equal "messages/assistant", message.to_partial_path
  end
end
