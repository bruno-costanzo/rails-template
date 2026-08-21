class SupportChatPhotosController < ApplicationController
  def create
    @chat = Current.user.chats.find_by!(support: true)
    @chat.pending_photos.attach(photo_params)

    render partial: "support_chats/photos", locals: { chat: @chat }
  end

  private

  def photo_params
    params.expect(chat: [ pending_photos: [] ])[:pending_photos]
  end
end
