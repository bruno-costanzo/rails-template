require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  test "the bell shows an unread badge, lists recent notifications, and marks them read" do
    sign_in_via_browser(users(:one))

    TestNotifier.deliver(users(:one))
    visit root_path

    find("[aria-label='Notifications']").click
    assert_selector ".badge-primary", text: "1"
    assert_text "Test notification"

    click_button "Mark all read"

    assert_no_selector ".badge-primary"
  end

  test "the dropdown stays open after the bell loses browser focus" do
    sign_in_via_browser(users(:one))

    TestNotifier.deliver(users(:one))
    visit root_path

    find("[aria-label='Notifications']").click
    page.driver.browser.execute_script("document.activeElement.blur()")

    assert_text "Test notification"
  end

  test "clicking outside the dropdown closes it" do
    sign_in_via_browser(users(:one))

    TestNotifier.deliver(users(:one))
    visit root_path

    find("[aria-label='Notifications']").click
    assert_text "Test notification"

    page.execute_script("arguments[0].click()", find("body").native)

    assert_no_text "Test notification"
  end

  test "shows a designed empty state when there are no notifications" do
    sign_in_via_browser(users(:one))

    find("[aria-label='Notifications']").click

    assert_text "You're all caught up"
  end
end
