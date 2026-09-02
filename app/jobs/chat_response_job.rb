class ChatResponseJob < ApplicationJob
  RETRY_ATTEMPTS = 3

  retry_on RubyLLM::Error, wait: 5.seconds, attempts: RETRY_ATTEMPTS do |job, error|
    job.broadcast_failure
    raise error
  end

  def perform(chat_id)
    support = Chat.where(id: chat_id).pick(:support)
    chat = support ? SupportAgent.find(chat_id) : Chat.find(chat_id)

    chat.complete do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end

    enqueue_title(chat)
  end

  def broadcast_failure
    chat_id = arguments.first

    Turbo::StreamsChannel.broadcast_append_to "chat_#{chat_id}",
      target: "chat_#{chat_id}_messages",
      partial: "messages/failure",
      locals: { chat_id: chat_id }
  end

  private

  def enqueue_title(chat)
    GenerateChatTitleJob.perform_later(chat) unless chat.support?
  rescue RubyLLM::Error => error
    Rails.error.report(error, handled: true, source: "chat_response_job")
  end
end
