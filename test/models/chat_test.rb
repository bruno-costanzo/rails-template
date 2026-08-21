require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "ask persists user and assistant messages via stubbed OpenAI" do
    stub_openai_chat(content: "Hello from the stub")
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    chat.ask("Say hello")
    assert_equal [ "user", "assistant" ], chat.messages.order(:created_at).pluck(:role)
    assert_includes chat.messages.last.content, "Hello from the stub"
  end

  test "support scope returns only chats flagged as support chats" do
    support_chat = users(:one).chats.create!(support: true)
    users(:one).chats.create!(model: "gpt-4o-mini")

    assert_equal [ support_chat ], users(:one).chats.support.to_a
  end

  test "is not a support chat by default" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    assert_not chat.support?
  end
end
