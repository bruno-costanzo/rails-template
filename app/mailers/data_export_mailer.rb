class DataExportMailer < ApplicationMailer
  def ready(user)
    @user = user
    @url = data_export_url
    mail subject: t(".subject"), to: user.email_address
  end
end
