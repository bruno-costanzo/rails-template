class SupportChatPhotosController < ApplicationController
  def create
    @chat = Current.user.chats.find_by!(support: true)
    @chat.pending_photos.attach(photo_params)

    if @chat.errors[:pending_photos].any?
      @chat.reload
      render partial: "support_chats/photos", locals: { chat: @chat, error: t("support_chat_photos.create.upload_error") }, status: :unprocessable_entity
    else
      render partial: "support_chats/photos", locals: { chat: @chat, error: nil }
    end
  end

  private

  def photo_params
    params.expect(chat: [ pending_photos: [] ])[:pending_photos]
  end
end
