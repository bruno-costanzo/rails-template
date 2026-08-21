require "test_helper"

class ChatResponseJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "enqueues chat titling after the response is persisted" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat(content: "Sure, here is how.")

    assert_enqueued_with(job: GenerateChatTitleJob, args: [ chat ]) do
      ChatResponseJob.perform_now(chat.id, "How do I deploy Rails with Kamal?")
    end
  end

  test "broadcasts each non-empty streamed chunk to the chat" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat_stream(chunks: [ "", "Sure", ", here", " is how." ])

    assert_broadcasts("chat_#{chat.id}", 7) do
      ChatResponseJob.perform_now(chat.id, "How do I deploy Rails with Kamal?")
    end

    assert_equal "Sure, here is how.", chat.messages.order(:created_at).last.content
  end

  test "a normal chat has no support instructions or tool attached" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat(content: "Sure, here is how.")

    ChatResponseJob.perform_now(chat.id, "How do I deploy with Kamal?")

    assert_nil chat.messages.find_by(role: "system")
  end

  test "a support chat's system instructions include the binding rule and the support context" do
    chat = users(:one).chats.create!(support: true)
    stub_openai_chat(content: "Sure, tell me more about what happened.")

    ChatResponseJob.perform_now(chat.id, "The chat page is slow for me")

    assert_requested :post, "https://api.openai.com/v1/chat/completions" do |request|
      instructions_message = JSON.parse(request.body)["messages"].find { |message| message["role"] != "user" }
      instructions_message &&
        instructions_message["content"].include?(SupportContext::BINDING_RULE) &&
        instructions_message["content"].include?(SupportContext.content)
    end
  end

  test "does not enqueue chat titling for a support chat" do
    chat = users(:one).chats.create!(support: true)
    stub_openai_chat(content: "Sure, tell me more about what happened.")

    assert_no_enqueued_jobs(only: GenerateChatTitleJob) do
      ChatResponseJob.perform_now(chat.id, "The chat page is slow for me")
    end
  end

  test "a support chat's tool call files a refined feedback ticket for the user" do
    chat = users(:one).chats.create!(support: true)
    stub_openai_chat_stream_with_tool_call(
      tool_name: "create_support_ticket",
      arguments: { title: "Chat page is slow", summary: "Pages take a long time to load for this person." },
      chunks: [ "Thanks, I've let the team know." ]
    )

    assert_difference("users(:one).feedbacks.count", 1) do
      ChatResponseJob.perform_now(chat.id, "The chat page loads slowly for me")
    end

    feedback = users(:one).feedbacks.last
    assert_includes feedback.message, "Chat page is slow"
    assert_includes feedback.message, "Pages take a long time to load for this person."
  end
end
