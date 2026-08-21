require "application_system_test_case"

class SupportChatTest < ApplicationSystemTestCase
  test "opening the widget and sending a message shows the stubbed human-friendly reply" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path

    stub_openai_chat_stream(chunks: [ "Thanks for reaching out, let's sort this out together." ])

    frame = find("turbo-frame#support_chat", visible: :all)
    assert_nil frame[:src]

    click_button "Support"
    assert_selector "dialog.modal", visible: true
    assert_equal support_chat_path, find("turbo-frame#support_chat", visible: :all)[:src]

    within "dialog.modal" do
      field = find_field("Message")
      page.execute_script("arguments[0].value = arguments[1]", field.native, "The chat page loads slowly for me")
      button = find_button("Send message")
      page.execute_script("arguments[0].click()", button.native)

      assert_text "The chat page loads slowly for me"
    end

    visit support_chat_url
    assert_text "Thanks for reaching out, let's sort this out together."
  end
end
