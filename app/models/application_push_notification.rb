class ApplicationPushNotification < ActionPushNative::Notification
  def self.credentials?(config = ActionPushNative.config)
    config.values.any? { |platform| platform[:encryption_key].present? }
  end

  self.enabled = credentials?
end
