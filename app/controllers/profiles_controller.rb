class ProfilesController < ApplicationController
  SECURITY_FIELDS = %w[ unconfirmed_email password password_confirmation password_challenge ].freeze

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    @user.assign_attributes(profile_params)

    if @user.save(context: :profile)
      EmailConfirmationsMailer.change(@user).deliver_later if @user.saved_change_to_unconfirmed_email?
      @user.sessions.where.not(id: Current.session.id).delete_all if @user.saved_change_to_password_digest?
      redirect_to edit_profile_url, notice: t("profiles.update.notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params
      .expect(user: [ :name, :avatar, :unconfirmed_email, :password, :password_confirmation, :password_challenge ])
      .reject { |key, value| SECURITY_FIELDS.include?(key) && value.blank? }
  end
end
