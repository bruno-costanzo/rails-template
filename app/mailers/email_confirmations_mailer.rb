class EmailConfirmationsMailer < ApplicationMailer
  def confirm(user)
    @user = user
    @token = user.generate_token_for(:email_confirmation)
    mail subject: t(".subject"), to: user.email_address
  end

  def change(user)
    @user = user
    @token = user.generate_token_for(:email_change)
    mail subject: t(".subject"), to: user.unconfirmed_email
  end
end
