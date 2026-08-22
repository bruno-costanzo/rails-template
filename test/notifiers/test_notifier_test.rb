require "test_helper"

class TestNotifierTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup { ActionMailer::Base.deliveries.clear }

  test "delivers a notification to a recipient and persists it" do
    user = users(:one)

    assert_difference -> { user.notifications.count }, 1 do
      TestNotifier.deliver(user)
    end
  end

  test "tracks unread and read state" do
    user = users(:one)
    TestNotifier.deliver(user)
    notification = user.notifications.last

    assert_equal 1, user.notifications.unread.count
    notification.mark_as_read!
    assert_equal 0, user.notifications.unread.count
  end

  test "does not send an email by default" do
    user = users(:one)

    perform_enqueued_jobs do
      TestNotifier.deliver(user)
    end

    assert_no_emails
  end

  test "sends an email when the recipient opts in" do
    user = users(:one)

    perform_enqueued_jobs do
      TestNotifier.with(send_email: true).deliver(user)
    end

    assert_emails 1
    assert_equal [ user.email_address ], ActionMailer::Base.deliveries.last.to
  end
end
