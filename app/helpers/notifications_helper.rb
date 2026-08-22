module NotificationsHelper
  def unread_notifications_count
    @unread_notifications_count ||= Current.user.notifications.unread.count
  end

  def recent_notifications
    @recent_notifications ||= Current.user.notifications.newest_first.includes(:event).limit(5).to_a
  end
end
