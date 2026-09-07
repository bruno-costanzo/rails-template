require "test_helper"

class ApplicationPushNotificationTest < ActiveSupport::TestCase
  test "delivery stays off while no platform carries an encryption key" do
    assert_not ApplicationPushNotification.credentials?,
      "the shipped config carries placeholders, and a delivery against them raises inside a job that never retries"
    assert_not ApplicationPushNotification.enabled
  end

  test "delivery turns on once a platform carries an encryption key" do
    assert ApplicationPushNotification.credentials?(apple: { encryption_key: "a key" }, google: { encryption_key: nil })
  end
end
