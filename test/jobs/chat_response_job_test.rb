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

    assert_broadcasts("chat_#{chat.id}", 3) do
      ChatResponseJob.perform_now(chat.id, "How do I deploy Rails with Kamal?")
    end

    assert_equal "Sure, here is how.", chat.messages.order(:created_at).last.content
  end
end
