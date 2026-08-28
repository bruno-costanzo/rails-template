require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    post chat_messages_url(chat), params: { message: { content: "Hi" } }
    assert_redirected_to new_session_url
  end

  test "enqueues a response and redirects for html requests" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(model: "gpt-4o-mini")

    assert_enqueued_with(job: ChatResponseJob, args: [ chat.id ]) do
      post chat_messages_url(chat), params: { message: { content: "How do I deploy with Kamal?" } }
    end

    assert_redirected_to chat
  end

  test "enqueues a response and renders a turbo stream" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(model: "gpt-4o-mini")

    assert_enqueued_with(job: ChatResponseJob, args: [ chat.id ]) do
      post chat_messages_url(chat), params: { message: { content: "How do I deploy with Kamal?" } }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
  end

  test "does nothing when the content is blank" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(model: "gpt-4o-mini")

    assert_no_enqueued_jobs(only: ChatResponseJob) do
      post chat_messages_url(chat), params: { message: { content: "" } }, as: :turbo_stream
    end

    assert_response :success
  end

  test "does not accept messages for another user's chat" do
    sign_in_as users(:one)
    other_chat = users(:two).chats.create!(model: "gpt-4o-mini")
    post chat_messages_url(other_chat), params: { message: { content: "Hi" } }
    assert_response :not_found
  end
  test "a closed conversation refuses new messages" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(support: true, closed_at: Time.current)

    assert_no_enqueued_jobs(only: ChatResponseJob) do
      post chat_messages_url(chat), params: { message: { content: "¿Hola?" } }
    end

    assert_response :forbidden
    assert_equal 0, chat.messages.count
  end
end
