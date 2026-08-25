require "test_helper"

class DataExportMailerTest < ActionMailer::TestCase
  test "ready email links to the download page" do
    user = users(:one)
    email = DataExportMailer.ready(user)

    assert_equal I18n.t("data_export_mailer.ready.subject"), email.subject
    assert_equal [ user.email_address ], email.to
    assert_match "/data_export", email.body.encoded
  end
end
