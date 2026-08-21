class SupportAgent < RubyLLM::Agent
  chat_model "Chat"

  instructions { SupportContext.instructions }

  tools { [ CreateSupportTicketTool.new(chat) ] }
end
