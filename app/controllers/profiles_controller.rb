class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    if @user.update(profile_params)
      redirect_to edit_profile_url, notice: "Profile updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    permitted = params.expect(user: [ :name, :email_address, :avatar, :password, :password_confirmation ])
    permitted.delete(:password) if permitted[:password].blank?
    permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
    permitted
  end
end
