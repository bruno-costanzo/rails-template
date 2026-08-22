require "application_system_test_case"

class ConfirmDialogTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_via_browser(@user)
  end

  test "cancelling the confirm dialog keeps the chat" do
    chat = @user.chats.create!(model: "gpt-4o-mini")
    visit chats_url
    assert_selector "#chat_#{chat.id}"
    assert_turbo_ready

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
    assert_turbo_ready

    click_button "Destroy"
    find("dialog#turbo-confirm", visible: true)
    assert_text "Are you sure?"

    click_dialog_button "confirm"
    assert_no_selector "#chat_#{chat.id}"
  end

  test "the confirm dialog stays ready after a Turbo Drive navigation" do
    visit chats_url
    assert_turbo_ready

    click_link "CharcoTemplate"
    assert_current_path root_path
    assert_turbo_ready
  end

  private

  def click_dialog_button(value)
    page.driver.browser.execute_script(
      "document.querySelector(arguments[0]).click()",
      "[data-turbo-confirm-#{value}]"
    )
  end
end
