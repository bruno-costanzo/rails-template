class EmailChangesController < ApplicationController
  allow_unauthenticated_access

  def show
    if User.find_by_token_for(:email_change, params[:token])&.confirm_email_change
      redirect_to root_path, notice: t(".confirmed")
    else
      redirect_to root_path, alert: t(".invalid")
    end
  end
end
