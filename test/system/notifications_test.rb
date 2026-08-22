require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  test "the bell shows an unread badge, lists recent notifications, and marks them read" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path

    TestNotifier.deliver(users(:one))
    visit root_path

    find("[aria-label='Notifications']").click
    assert_selector ".badge-primary", text: "1"
    assert_text "Test notification"

    click_button "Mark all read"

    assert_no_selector ".badge-primary"
  end

  test "the dropdown stays open after the bell loses browser focus" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path

    TestNotifier.deliver(users(:one))
    visit root_path

    find("[aria-label='Notifications']").click
    page.driver.browser.execute_script("document.activeElement.blur()")

    assert_text "Test notification"
  end

  test "clicking outside the dropdown closes it" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path

    TestNotifier.deliver(users(:one))
    visit root_path

    find("[aria-label='Notifications']").click
    assert_text "Test notification"

    find("body").click

    assert_no_text "Test notification"
  end

  test "shows a designed empty state when there are no notifications" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path

    find("[aria-label='Notifications']").click

    assert_text "You're all caught up"
  end
end
