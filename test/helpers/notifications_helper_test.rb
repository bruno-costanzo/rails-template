require "test_helper"

class NotificationsHelperTest < ActionView::TestCase
  setup { Current.session = users(:one).sessions.create! }
  teardown { Current.session = nil }

  test "unread_notifications_count counts only unread notifications for the current user" do
    TestNotifier.deliver(users(:one))
    TestNotifier.deliver(users(:two))

    assert_equal 1, unread_notifications_count
  end

  test "recent_notifications returns the current user's notifications newest first" do
    older = TestNotifier.deliver(users(:one)).notifications.first
    newer = TestNotifier.deliver(users(:one)).notifications.first
    older.update_columns(created_at: 1.hour.ago)

    assert_equal [ newer, older ], recent_notifications.to_a
  end
end
