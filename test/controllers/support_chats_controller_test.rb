require "test_helper"

class SupportChatsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get support_chat_url
    assert_redirected_to new_session_url
  end

  test "creates the user's support chat on first visit" do
    sign_in_as users(:one)

    assert_difference("users(:one).chats.support.count", 1) do
      get support_chat_url
    end

    assert_response :success
  end

  test "reuses the existing support chat on subsequent visits" do
    sign_in_as users(:one)
    get support_chat_url

    assert_no_difference("users(:one).chats.support.count") do
      get support_chat_url
    end
  end

  test "does not render technical tool call details for the person" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(support: true)
    message = chat.messages.create!(role: :assistant, content: "")
    message.tool_calls.create!(tool_call_id: "call_1", name: "create_support_ticket", arguments: { title: "x", summary: "y" })

    get support_chat_url

    assert_response :success
    assert_no_match "create_support_ticket", @response.body
  end
end
