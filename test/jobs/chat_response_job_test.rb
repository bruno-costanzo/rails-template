require "test_helper"

class ChatResponseJobTest < ActiveJob::TestCase
  test "enqueues chat titling after the response is persisted" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    stub_openai_chat(content: "Sure, here is how.")

    assert_enqueued_with(job: GenerateChatTitleJob, args: [ chat ]) do
      ChatResponseJob.perform_now(chat.id, "How do I deploy Rails with Kamal?")
    end
  end
end
