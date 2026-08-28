class MessagesController < ApplicationController
  before_action :set_chat
  before_action :ensure_open, only: :create

  def create
    content = params.dig(:message, :content)
    if content.present?
      @user_message = @chat.messages.create!(role: :user, content: content)
      ChatResponseJob.perform_later(@chat.id)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat }
      end
    end
  end

  private

  def ensure_open
    head :forbidden if @chat.closed?
  end

  def set_chat
    @chat = Current.user.chats.find(params[:chat_id])
  end
end
