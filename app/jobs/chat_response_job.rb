class ChatResponseJob < ApplicationJob
  def perform(chat_id, content)
    support = Chat.where(id: chat_id).pick(:support)
    chat = support ? SupportAgent.find(chat_id) : Chat.find(chat_id)

    chat.ask(content) do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end

    GenerateChatTitleJob.perform_later(chat) unless chat.support?
  end
end
