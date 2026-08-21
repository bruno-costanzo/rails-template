SolidErrors.username = Rails.application.credentials.dig(:solid_errors, :username) || ENV["SOLID_ERRORS_USERNAME"]
SolidErrors.password = Rails.application.credentials.dig(:solid_errors, :password) || ENV["SOLID_ERRORS_PASSWORD"]
SolidErrors.email_to = Rails.application.credentials.dig(:solid_errors, :email_to) || ENV["SOLID_ERRORS_EMAIL_TO"]
SolidErrors.email_from = Rails.application.credentials.dig(:solid_errors, :email_from) || ENV["SOLID_ERRORS_EMAIL_FROM"] || SolidErrors.email_from
SolidErrors.send_emails = SolidErrors.email_to.present?
