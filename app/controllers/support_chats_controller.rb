class SupportChatsController < ApplicationController
  CONTEXT_KEYS = %i[page_url user_agent viewport].freeze
  CONTEXT_VALUE_LIMIT = 2.kilobytes

  def show
    @chat = Current.user.chats.find_or_create_by!(support: true)
    @chat.update!(ticket_context: context_params) if context_params.present?
    @message = @chat.messages.build
  end

  private

  def context_params
    params.fetch(:context, {}).permit(*CONTEXT_KEYS).to_h.transform_values { |value| sanitize_context_value(value) }
  end

  def sanitize_context_value(value)
    value.to_s.gsub(/\r?\n/, " ").byteslice(0, CONTEXT_VALUE_LIMIT).scrub("")
  end
end
