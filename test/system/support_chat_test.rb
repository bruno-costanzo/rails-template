require "application_system_test_case"

class SupportChatTest < ApplicationSystemTestCase
  test "opening the widget and sending a message shows the stubbed human-friendly reply" do
    sign_in_via_browser(users(:one))

    stub_openai_chat_stream(chunks: [ "Thanks for reaching out, let's sort this out together." ])

    frame = find("turbo-frame#support_chat", visible: :all)
    assert_nil frame[:src]

    click_button "Support"
    assert_selector "dialog.modal", visible: true

    frame_src = URI.parse(find("turbo-frame#support_chat", visible: :all)[:src])
    assert_equal support_chat_path, frame_src.path
    context = Rack::Utils.parse_nested_query(frame_src.query)["context"]
    assert context["page_url"].present?
    assert context["user_agent"].present?
    assert context["viewport"].present?

    within "dialog.modal" do
      fill_in "Message", with: "The chat page loads slowly for me"
      click_button "Send message"

      assert_text "The chat page loads slowly for me"
    end

    visit support_chat_url
    assert_text "Thanks for reaching out, let's sort this out together."
  end

  test "attaching a photo before filing a ticket carries the photo to the resulting feedback" do
    sign_in_via_browser(users(:one))

    stub_openai_chat_stream_with_tool_call(
      tool_name: "create_support_ticket",
      arguments: { title: "Broken layout", summary: "The layout breaks on this page." },
      chunks: [ "Got it - I've passed this along to the team. Thank you!" ]
    )

    click_button "Support"
    assert_selector "dialog.modal", visible: true

    attach_file "chat_pending_photos", file_fixture("avatar.png")
    assert_text "1 photo attached"

    fill_in "Message", with: "The layout looks broken on this page"
    click_button "Send message"

    assert_text "Got it - I've passed this along to the team. Thank you!"

    feedback = Feedback.last
    assert feedback.photos.attached?
  end
end
