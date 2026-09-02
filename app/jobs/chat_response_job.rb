class ChatResponseJob < ApplicationJob
  def perform(chat_id)
    support = Chat.where(id: chat_id).pick(:support)
    chat = support ? SupportAgent.find(chat_id) : Chat.find(chat_id)

    chat.complete do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end

    GenerateChatTitleJob.perform_later(chat) unless chat.support?
  rescue RubyLLM::Error
    broadcast_failure(chat_id)
    raise
  end

  private

  def broadcast_failure(chat_id)
    Turbo::StreamsChannel.broadcast_append_to "chat_#{chat_id}",
      target: "chat_#{chat_id}_messages",
      partial: "messages/failure"
  end
end
