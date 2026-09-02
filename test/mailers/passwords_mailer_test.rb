require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset addresses the user and includes a reset link" do
    user = users(:one)

    email = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], email.to
    assert_equal I18n.t("passwords_mailer.reset.subject"), email.subject
    assert_match %r{http://example\.com/passwords/[\w=-]+/edit}, email.text_part.decoded
  end
end
