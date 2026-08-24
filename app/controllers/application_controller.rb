class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  private

  def pundit_user
    Current.user
  end

  def user_not_authorized
    redirect_back_or_to root_path, alert: "You are not authorized to perform this action."
  end

  def available_chat_models
    RubyLLM.models.chat_models.all
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end
end
