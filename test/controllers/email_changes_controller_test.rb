require "test_helper"

class EmailChangesControllerTest < ActionDispatch::IntegrationTest
  test "show confirms the pending email with a valid token" do
    user = users(:one)
    user.update!(unconfirmed_email: "ada-new@example.com")
    token = user.generate_token_for(:email_change)

    get email_change_url(token)

    assert_redirected_to root_url
    assert_equal I18n.t("email_changes.show.confirmed"), flash[:notice]
    assert_equal "ada-new@example.com", user.reload.email_address
    assert_nil user.unconfirmed_email
  end

  test "show rejects an invalid token" do
    get email_change_url("not-a-token")

    assert_redirected_to root_url
    assert_equal I18n.t("email_changes.show.invalid"), flash[:alert]
  end

  test "show rejects an expired token" do
    user = users(:one)
    user.update!(unconfirmed_email: "ada-new@example.com")
    token = user.generate_token_for(:email_change)

    travel_to User::EMAIL_CONFIRMATION_EXPIRES_IN.from_now + 1.minute do
      get email_change_url(token)
    end

    assert_redirected_to root_url
    assert_equal I18n.t("email_changes.show.invalid"), flash[:alert]
    assert_equal "ada@example.com", user.reload.email_address
  end

  test "show refuses when the address was taken meanwhile" do
    user = users(:one)
    user.update!(unconfirmed_email: "taken@example.com")
    token = user.generate_token_for(:email_change)
    users(:two).update!(email_address: "taken@example.com")

    get email_change_url(token)

    assert_redirected_to root_url
    assert_equal I18n.t("email_changes.show.invalid"), flash[:alert]
    assert_equal "ada@example.com", user.reload.email_address
  end
end
