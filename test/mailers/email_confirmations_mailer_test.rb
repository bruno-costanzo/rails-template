require "test_helper"

class EmailConfirmationsMailerTest < ActionMailer::TestCase
  test "confirm addresses the user and includes a confirmation link" do
    user = User.create!(name: "Unconf", email_address: "mailer@example.com", password: "password1234")

    email = EmailConfirmationsMailer.confirm(user)

    assert_equal [ user.email_address ], email.to
    assert_equal I18n.t("email_confirmations_mailer.confirm.subject"), email.subject
    assert_match %r{http://example\.com/email_confirmations/[\w.-]+}, email.body.encoded.gsub("=\r\n", "")
  end

  test "change addresses the pending email and includes an email change link" do
    user = users(:one)
    user.update!(unconfirmed_email: "ada-new@example.com")

    email = EmailConfirmationsMailer.change(user)

    assert_equal [ "ada-new@example.com" ], email.to
    assert_equal I18n.t("email_confirmations_mailer.change.subject"), email.subject
    assert_match %r{http://example\.com/email_changes/[\w.-]+}, email.body.encoded.gsub("=\r\n", "")
  end
end
