require "application_system_test_case"

class SupportChatTest < ApplicationSystemTestCase
  test "the widget opens on the conversation list and carries the page context into a new one" do
    sign_in_via_browser(users(:one))

    frame = find("turbo-frame#support_chat", visible: :all)
    assert_nil frame[:src]

    click_button "Support"
    assert_selector "dialog.modal", visible: true

    frame_src = URI.parse(find("turbo-frame#support_chat", visible: :all)[:src])
    assert_equal support_chats_path, frame_src.path
    context = Rack::Utils.parse_nested_query(frame_src.query)["context"]
    assert context["page_url"].present?
    assert context["user_agent"].present?
    assert context["viewport"].present?

    within "dialog.modal" do
      click_button "New conversation"
      assert_selector "#new_message"
    end

    chat = users(:one).chats.support.sole
    assert_equal context["page_url"], chat.ticket_context["page_url"]
  end

  test "sending a message shows the stubbed human-friendly reply without leaving the widget" do
    sign_in_via_browser(users(:one))

    stub_openai_chat_stream(chunks: [ "Thanks for reaching out, let's sort this out together." ])

    click_button "Support"
    within "dialog.modal" do
      click_button "New conversation"
      fill_in "Your message", with: "The chat page loads slowly for me"
      click_button "Send"

      assert_text "The chat page loads slowly for me"
      assert_text "Thanks for reaching out, let's sort this out together."
    end
  end

  test "past conversations are listed and can be reopened" do
    user = users(:one)
    past = user.chats.create!(support: true)
    past.messages.create!(role: :user, content: "Mi factura salio mal")

    sign_in_via_browser(user)

    click_button "Support"
    within "dialog.modal" do
      click_link "Mi factura salio mal"
      assert_selector "#new_message"
      assert_text "Mi factura salio mal"
    end
  end

  test "attaching a photo before filing a ticket carries the photo to the resulting feedback" do
    sign_in_via_browser(users(:one))

    stub_openai_chat_stream_with_tool_call(
      tool_name: "create_support_ticket",
      arguments: { title: "Broken layout", summary: "The layout breaks on this page." },
      chunks: [ "Got it - I've passed this along to the team. Thank you!" ]
    )

    click_button "Support"
    within "dialog.modal" do
      click_button "New conversation"
      chat = users(:one).chats.support.sole
      attach_file "chat_pending_photos", file_fixture("avatar.png"), make_visible: true
      assert_text "1 photo attached"

      fill_in "Your message", with: "The layout looks broken on this page"
      click_button "Send"

      assert_text "Got it - I've passed this along to the team. Thank you!"
      assert chat
    end

    feedback = Feedback.last
    assert feedback.photos.attached?
  end
end
