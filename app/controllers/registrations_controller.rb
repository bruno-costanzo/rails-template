class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      EmailConfirmationsMailer.confirm(@user).deliver_later
      redirect_to new_session_path, notice: t("registrations.create.notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:confirmation].to_s.strip == t("registrations.destroy.confirmation_phrase") && Current.user.authenticate(params[:password])
      Current.user.destroy
      terminate_session
      redirect_to new_session_path, notice: t("registrations.destroy.notice")
    else
      redirect_to edit_profile_path, alert: t("registrations.destroy.error")
    end
  end

  private

  def registration_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
  end
end
