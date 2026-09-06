require "test_helper"

class DeliveryMethods::PushNativeTest < ActiveSupport::TestCase
  class PushTestNotifier < Noticed::Event
    deliver_by :push_native, class: "DeliveryMethods::PushNative" do |config|
      config.title = "Ping"
      config.body = -> { params[:body] }
      config.path = -> { params[:path] }
      config.badge = 3
    end
  end

  test "delivers to every device the recipient registered" do
    user = users(:one)
    user.push_devices.create!(token: "apple-token", platform: "apple", name: "iPhone")
    user.push_devices.create!(token: "google-token", platform: "google", name: "Pixel")

    assert_enqueued_jobs 2, only: ApplicationPushNotificationJob do
      perform_enqueued_jobs(except: ApplicationPushNotificationJob) do
        PushTestNotifier.with(body: "Hello", path: "/notifications").deliver(user)
      end
    end
  end

  test "is a no-op for a person without devices" do
    assert_no_enqueued_jobs only: ApplicationPushNotificationJob do
      perform_enqueued_jobs(except: ApplicationPushNotificationJob) do
        PushTestNotifier.with(body: "Hello", path: "/notifications").deliver(users(:two))
      end
    end
  end
end
