class ChatResponseJob < ApplicationJob
  def perform(chat_id, content)
    chat = Chat.find(chat_id)
    attach_support_tooling(chat) if chat.support?

    chat.ask(content) do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end

    GenerateChatTitleJob.perform_later(chat) unless chat.support?
  end

  private

  def attach_support_tooling(chat)
    chat.with_instructions(SupportContext.instructions)
    chat.with_tool(CreateSupportTicketTool.new(chat.user))
  end
end
