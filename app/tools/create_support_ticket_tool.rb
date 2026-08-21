class CreateSupportTicketTool < RubyLLM::Tool
  description "Files a refined support ticket with the team once the person's problem or suggestion is understood."

  param :title, desc: "A short, plain-language title for the ticket"
  param :summary, desc: "A clear, plain-language summary of the problem or suggestion, written for the app's developer"

  def initialize(user)
    super()
    @user = user
  end

  def execute(title:, summary:)
    @user.feedbacks.create!(message: "#{title}\n\n#{summary}")

    "Got it - I've passed this along to the team. Thank you!"
  end
end
