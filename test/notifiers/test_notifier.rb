class TestNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "TestNotifierMailer"
    config.method = :notify
    config.if = -> { params[:send_email] }
  end

  notification_methods do
    def message
      params[:message] || "Test notification"
    end
  end
end
