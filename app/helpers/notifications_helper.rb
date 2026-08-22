module NotificationsHelper
  def unread_notifications_count
    Current.user.notifications.unread.count
  end

  def recent_notifications
    Current.user.notifications.newest_first.limit(5)
  end
end
