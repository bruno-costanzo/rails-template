module DeliveryMethods
  class PushNative < Noticed::DeliveryMethod
    required_options :title

    def deliver
      devices = recipient.push_devices
      return if devices.none?

      ApplicationPushNotification
        .with_data(path: evaluate_option(:path).to_s)
        .new(title: evaluate_option(:title), body: evaluate_option(:body), badge: evaluate_option(:badge))
        .deliver_later_to(devices)
    end
  end
end
