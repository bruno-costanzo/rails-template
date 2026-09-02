class NotificationsController < ApplicationController
  def index
    @notifications = Current.user.notifications.newest_first.includes(:event)
  end

  def mark_all_read
    Current.user.notifications.unread.mark_as_read
    redirect_back_or_to notifications_path
  end
end
