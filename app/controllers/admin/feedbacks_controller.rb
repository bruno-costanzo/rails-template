module Admin
  class FeedbacksController < ApplicationController
    include SuperadminAuthentication

    allow_unauthenticated_access

    def index
      @feedbacks = Feedback.open.includes(:user, photos_attachments: :blob).order(created_at: :desc)
    end

    def resolve
      Feedback.find(params[:id]).resolve!
      redirect_to admin_feedbacks_path, notice: "Ticket resolved."
    end
  end
end
