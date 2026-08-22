require "application_system_test_case"

class FlashToastTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "a failed login shows an error toast" do
    sign_in_with_wrong_password

    assert_selector ".toast .alert.alert-error", text: "Try another email address or password.", visible: true
  end

  test "the dismiss button removes the toast" do
    sign_in_with_wrong_password
    assert_selector ".toast .alert.alert-error", visible: true

    within ".toast .alert.alert-error" do
      find("button[aria-label='Dismiss']").click
    end

    assert_no_selector ".toast .alert.alert-error"
  end

  test "the toast auto-dismisses after the timeout" do
    sign_in_with_wrong_password
    assert_selector ".toast .alert.alert-error", visible: true

    assert_no_selector ".toast .alert.alert-error", wait: 8
  end

  private

  def sign_in_with_wrong_password
    visit new_session_url
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "wrong-password"
    click_button "Sign in"
  end
end
