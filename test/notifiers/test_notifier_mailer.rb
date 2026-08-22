class TestNotifierMailer < ApplicationMailer
  def notify
    @notification = params[:notification]

    mail(
      to: params[:recipient].email_address,
      subject: "Test notification",
      body: "You have a new test notification.",
      content_type: "text/plain"
    )
  end
end
