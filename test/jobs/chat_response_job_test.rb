require "test_helper"

class ChatResponseJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "enqueues chat titling after the response is persisted" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat(content: "Sure, here is how.")

    assert_enqueued_with(job: GenerateChatTitleJob, args: [ chat ]) do
      chat.messages.create!(role: :user, content: "How do I deploy Rails with Kamal?")
      ChatResponseJob.perform_now(chat.id)
    end
  end

  test "broadcasts each non-empty streamed chunk to the chat" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat_stream(chunks: [ "", "Sure", ", here", " is how." ])

    assert_broadcasts("chat_#{chat.id}", 6) do
      chat.messages.create!(role: :user, content: "How do I deploy Rails with Kamal?")
      ChatResponseJob.perform_now(chat.id)
    end

    assert_equal "Sure, here is how.", chat.messages.order(:created_at).last.content
  end

  test "a normal chat has no support instructions or tool attached" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat(content: "Sure, here is how.")

    chat.messages.create!(role: :user, content: "How do I deploy with Kamal?")
      ChatResponseJob.perform_now(chat.id)

    assert_nil chat.messages.find_by(role: "system")
  end

  test "a support chat's system instructions include the binding rule and the support context" do
    chat = users(:one).chats.create!(support: true)
    stub_openai_chat(content: "Sure, tell me more about what happened.")

    chat.messages.create!(role: :user, content: "The chat page is slow for me")
      ChatResponseJob.perform_now(chat.id)

    assert_requested :post, "https://api.openai.com/v1/chat/completions" do |request|
      instructions_message = JSON.parse(request.body)["messages"].find { |message| message["role"] != "user" }
      instructions_message &&
        instructions_message["content"].include?(SupportContext::BINDING_RULE) &&
        instructions_message["content"].include?(SupportContext.content)
    end
  end

  test "a support chat with a pre-existing persisted system message does not duplicate instructions" do
    chat = users(:one).chats.create!(support: true)
    chat.messages.create!(role: "system", content: "Stale instructions from before this refactor")
    stub_openai_chat(content: "Sure, tell me more about what happened.")

    chat.messages.create!(role: :user, content: "The chat page is slow for me")
      ChatResponseJob.perform_now(chat.id)

    assert_requested :post, "https://api.openai.com/v1/chat/completions" do |request|
      request.body.scan(SupportContext::BINDING_RULE).count == 1
    end
  end

  test "does not enqueue chat titling for a support chat" do
    chat = users(:one).chats.create!(support: true)
    stub_openai_chat(content: "Sure, tell me more about what happened.")

    assert_no_enqueued_jobs(only: GenerateChatTitleJob) do
      chat.messages.create!(role: :user, content: "The chat page is slow for me")
      ChatResponseJob.perform_now(chat.id)
    end
  end

  test "rescues a provider error, broadcasts a human-friendly failure, and re-raises" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    chat.messages.create!(role: :user, content: "How do I deploy with Kamal?")
    stub_openai_chat_error(status: 500)

    clear_messages("chat_#{chat.id}")

    assert_raises(RubyLLM::Error) { ChatResponseJob.perform_now(chat.id) }

    raw_broadcasts = broadcasts("chat_#{chat.id}")
    failure_broadcasts = raw_broadcasts.map { |raw| JSON.parse(raw) }.select { |broadcasted| broadcasted.include?(I18n.t("messages.failure.body")) }

    assert_equal 1, failure_broadcasts.size
    failure_broadcast = failure_broadcasts.first
    assert_match(/action="append"/, failure_broadcast)
    assert_match(/target="chat_#{chat.id}_messages"/, failure_broadcast)
    assert_no_match "500", failure_broadcast
    assert_no_match "Internal server error", failure_broadcast

    assert_nil chat.messages.reload.find_by(role: :assistant)
  end

  test "a support chat's tool call files a refined feedback ticket for the user" do
    chat = users(:one).chats.create!(support: true)
    stub_openai_chat_stream_with_tool_call(
      tool_name: "create_support_ticket",
      arguments: { title: "Chat page is slow", summary: "Pages take a long time to load for this person." },
      chunks: [ "Thanks, I've let the team know." ]
    )

    assert_difference("users(:one).feedbacks.count", 1) do
      chat.messages.create!(role: :user, content: "The chat page loads slowly for me")
      ChatResponseJob.perform_now(chat.id)
    end

    feedback = users(:one).feedbacks.last
    assert_includes feedback.message, "Chat page is slow"
    assert_includes feedback.message, "Pages take a long time to load for this person."
  end
end
