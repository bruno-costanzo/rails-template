require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper
  include QueryCountHelper

  test "requires authentication" do
    get notifications_url
    assert_redirected_to new_session_url
  end

  test "shows a designed empty state when there are no notifications" do
    sign_in_as users(:one)

    get notifications_url

    assert_response :success
    assert_select "p", text: I18n.t("notifications.index.empty")
  end

  test "lists only the current user's notifications" do
    sign_in_as users(:one)
    TestNotifier.deliver(users(:one))
    TestNotifier.deliver(users(:two))

    get notifications_url

    assert_select "#notification_list li", text: /Test notification/, count: 1
  end

  test "renders a read notification without the unread badge or styling" do
    sign_in_as users(:one)
    TestNotifier.deliver(users(:one))
    users(:one).notifications.first.mark_as_read!

    get notifications_url

    assert_select ".badge-primary", count: 0
    assert_select "div.font-semibold", count: 0
    assert_select "#notification_list li", text: /Test notification/, count: 1
  end

  test "renders multiple notifications without an N+1" do
    sign_in_as users(:one)
    3.times { TestNotifier.deliver(users(:one)) }

    get notifications_url

    assert_response :success
  end

  test "the navbar bell stays within a fixed query budget" do
    sign_in_as users(:one)
    3.times { TestNotifier.deliver(users(:one)) }

    queries = count_queries(matching: /noticed_notifications|noticed_events/) { get root_url }

    assert_operator queries, :<=, 3
  end

  test "mark_all_read marks all unread notifications as read and redirects back" do
    sign_in_as users(:one)
    TestNotifier.deliver(users(:one))

    patch mark_all_read_notifications_url, headers: { "HTTP_REFERER" => notifications_url }

    assert_redirected_to notifications_url
    assert_equal 0, users(:one).notifications.unread.count
  end

  test "mark_all_read only touches the current user's notifications" do
    sign_in_as users(:one)
    TestNotifier.deliver(users(:two))

    patch mark_all_read_notifications_url

    assert_equal 1, users(:two).notifications.unread.count
  end
end
