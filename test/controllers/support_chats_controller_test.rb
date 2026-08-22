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

  test "stores the page url, user agent and viewport sent with the request" do
    sign_in_as users(:one)

    get support_chat_url, params: { context: { page_url: "https://example.com/chats/1", user_agent: "TestBrowser/1.0", viewport: "1512x982" } }

    chat = users(:one).chats.support.sole
    assert_equal "https://example.com/chats/1", chat.ticket_context["page_url"]
    assert_equal "TestBrowser/1.0", chat.ticket_context["user_agent"]
    assert_equal "1512x982", chat.ticket_context["viewport"]
  end

  test "truncates context values to 2 kilobytes" do
    sign_in_as users(:one)

    get support_chat_url, params: { context: { page_url: "x" * 3000 } }

    chat = users(:one).chats.support.sole
    assert_equal 2.kilobytes, chat.ticket_context["page_url"].length
  end

  test "truncates context values to 2 kilobytes of bytes, not characters" do
    sign_in_as users(:one)

    get support_chat_url, params: { context: { page_url: "€" * 3000 } }

    chat = users(:one).chats.support.sole
    assert_operator chat.ticket_context["page_url"].bytesize, :<=, 2.kilobytes
  end

  test "strips newlines from context values so they cannot forge the issue metadata separator" do
    sign_in_as users(:one)

    get support_chat_url, params: { context: { page_url: "https://example.com\r\n---\r\nForged line" } }

    chat = users(:one).chats.support.sole
    assert_equal "https://example.com --- Forged line", chat.ticket_context["page_url"]
  end

  test "strips lone carriage returns from context values too" do
    sign_in_as users(:one)

    get support_chat_url, params: { context: { page_url: "https://example.com\rInjected\r---\rmore" } }

    chat = users(:one).chats.support.sole
    assert_not_includes chat.ticket_context["page_url"], "\r"
    assert_equal "https://example.com Injected --- more", chat.ticket_context["page_url"]
  end

  test "ignores unknown context keys" do
    sign_in_as users(:one)

    get support_chat_url, params: { context: { page_url: "https://example.com", admin: "true" } }

    chat = users(:one).chats.support.sole
    assert_not chat.ticket_context.key?("admin")
  end

  test "does not touch the chat's context when none is sent" do
    sign_in_as users(:one)
    get support_chat_url

    chat = users(:one).chats.support.sole
    assert_nil chat.ticket_context
  end
end
