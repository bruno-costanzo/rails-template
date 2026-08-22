class NotificationsController < ApplicationController
  def index
    @notifications = Current.user.notifications.newest_first
  end

  def mark_all_read
    Current.user.notifications.unread.mark_as_read
    redirect_back fallback_location: notifications_path
  end
end
