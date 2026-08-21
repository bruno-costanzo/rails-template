class CreateSupportTicketTool < RubyLLM::Tool
  description "Files a refined support ticket with the team once the person's problem or suggestion is understood."

  param :title, desc: "A short, plain-language title for the ticket"
  param :summary, desc: "A clear, plain-language summary of the problem or suggestion, written for the app's developer"

  def initialize(chat)
    super()
    @chat = chat
    @user = chat.user
  end

  def execute(title:, summary:)
    feedback = @user.feedbacks.create!(message: "#{title}\n\n#{summary}", context: @chat.ticket_context)
    transfer_pending_photos(feedback)

    "Got it - I've passed this along to the team. Thank you!"
  end

  private

  def transfer_pending_photos(feedback)
    return unless @chat.pending_photos.attached?

    feedback.photos.attach(@chat.pending_photos.map(&:blob))
    @chat.pending_photos.detach
  end
end
