class SupportChatsController < ApplicationController
  def show
    @chat = Current.user.chats.find_or_create_by!(support: true)
    @message = @chat.messages.build
  end
end
