class OnlylogsBaseController < ActionController::Base
  private

  def authenticate_onlylogs_user!
    username = Rails.application.credentials.dig(:onlylogs, :basic_auth_user) || ENV["ONLYLOGS_BASIC_AUTH_USER"]
    password = Rails.application.credentials.dig(:onlylogs, :basic_auth_password) || ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"]

    return request_http_basic_authentication if username.blank? || password.blank?

    authenticate_or_request_with_http_basic do |given_username, given_password|
      ActiveSupport::SecurityUtils.secure_compare(given_username, username) &
        ActiveSupport::SecurityUtils.secure_compare(given_password, password)
    end
  end
end
