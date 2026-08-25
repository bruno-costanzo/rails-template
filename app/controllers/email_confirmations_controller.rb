class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_email_confirmation_path, alert: t("email_confirmations.rate_limit") }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      EmailConfirmationsMailer.confirm(user).deliver_later unless user.confirmed?
    end

    redirect_to new_session_path, notice: t(".notice")
  end

  def show
    if user = User.find_by_token_for(:email_confirmation, params[:token])
      user.confirm!
      redirect_to new_session_path, notice: t(".confirmed")
    else
      redirect_to new_email_confirmation_path, alert: t(".invalid")
    end
  end
end
