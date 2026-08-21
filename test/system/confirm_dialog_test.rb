require "application_system_test_case"

class ConfirmDialogTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser
  end

  test "cancelling the confirm dialog keeps the chat" do
    chat = @user.chats.create!(model: "gpt-4o-mini")
    visit chats_url
    assert_selector "#chat_#{chat.id}"

    click_button "Destroy"
    find("dialog#turbo-confirm", visible: true)
    assert_text "Are you sure?"

    click_dialog_button "cancel"
    assert_no_selector "dialog#turbo-confirm", visible: true
    assert_selector "#chat_#{chat.id}"
  end

  test "confirming the confirm dialog destroys the chat" do
    chat = @user.chats.create!(model: "gpt-4o-mini")
    visit chats_url
    assert_selector "#chat_#{chat.id}"

    click_button "Destroy"
    find("dialog#turbo-confirm", visible: true)
    assert_text "Are you sure?"

    click_dialog_button "confirm"
    assert_no_selector "#chat_#{chat.id}"
  end

  private

  def sign_in_via_browser
    visit new_session_url
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path
  end

  def click_dialog_button(value)
    page.driver.browser.execute_script(
      "document.querySelector(arguments[0]).click()",
      "[data-turbo-confirm-#{value}]"
    )
  end
end
