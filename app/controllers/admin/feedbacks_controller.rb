module Admin
  class FeedbacksController < ApplicationController
    allow_unauthenticated_access
    before_action :authenticate_admin

    def index
      @feedbacks = Feedback.open.includes(:user, photos_attachments: :blob).order(created_at: :desc)
    end

    def resolve
      Feedback.find(params[:id]).resolve!
      redirect_to admin_feedbacks_path, notice: "Ticket resolved."
    end

    private

    def authenticate_admin
      username = Rails.application.credentials.dig(:admin, :username) || ENV["ADMIN_USERNAME"]
      password = Rails.application.credentials.dig(:admin, :password) || ENV["ADMIN_PASSWORD"]

      return request_http_basic_authentication if username.blank? || password.blank?

      authenticate_or_request_with_http_basic do |given_username, given_password|
        ActiveSupport::SecurityUtils.secure_compare(given_username, username) &
          ActiveSupport::SecurityUtils.secure_compare(given_password, password)
      end
    end
  end
end
