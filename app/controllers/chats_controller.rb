class ChatsController < ApplicationController
  before_action :set_chat, only: [ :show, :destroy ]

  def index
    @chats = Current.user.chats.where(support: false).order(created_at: :desc)
  end

  def new
    @chat = Chat.new
    @selected_model = params[:model]
    @chat_models = available_chat_models
  end

  def create
    prompt = params.dig(:chat, :prompt)
    if prompt.present?
      @chat = Current.user.chats.create!(model: params.dig(:chat, :model).presence)
      ChatResponseJob.perform_later(@chat.id, prompt)

      redirect_to @chat, notice: t("chats.create.notice")
    end
  end

  def show
    @message = @chat.messages.build
    @messages = @chat.messages.where.not(id: nil).includes(:tool_calls, :parent_tool_call, :model, attachments_attachments: :blob)
  end

  def destroy
    @chat.destroy!
    redirect_to chats_path, notice: t("chats.destroy.notice"), status: :see_other
  end

  private

  def set_chat
    @chat = Current.user.chats.find(params[:id])
  end
end
