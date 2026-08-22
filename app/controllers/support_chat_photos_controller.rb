class SupportChatPhotosController < ApplicationController
  UPLOAD_ERROR = "That photo couldn't be attached. Please use a JPG, PNG, or WEBP image under 5MB.".freeze

  def create
    @chat = Current.user.chats.find_by!(support: true)
    @chat.pending_photos.attach(photo_params)

    if @chat.errors[:pending_photos].any?
      @chat.reload
      render partial: "support_chats/photos", locals: { chat: @chat, error: UPLOAD_ERROR }, status: :unprocessable_entity
    else
      render partial: "support_chats/photos", locals: { chat: @chat, error: nil }
    end
  end

  private

  def photo_params
    params.expect(chat: [ pending_photos: [] ])[:pending_photos]
  end
end
