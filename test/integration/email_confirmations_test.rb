require "test_helper"

class EmailConfirmationsTest < ActionDispatch::IntegrationTest
  test "new renders the resend form" do
    get new_email_confirmation_url

    assert_response :success
  end

  test "create sends a confirmation email to an unconfirmed user" do
    user = User.create!(name: "Unconf", email_address: "unconf@example.com", password: "password1234")

    assert_enqueued_emails 1 do
      post email_confirmations_url, params: { email_address: user.email_address }
    end

    assert_redirected_to new_session_url
  end

  test "create does not email an already-confirmed user" do
    assert_no_enqueued_emails do
      post email_confirmations_url, params: { email_address: users(:one).email_address }
    end

    assert_redirected_to new_session_url
  end

  test "create redirects without leaking whether an unknown email exists" do
    assert_no_enqueued_emails do
      post email_confirmations_url, params: { email_address: "nobody@example.com" }
    end

    assert_redirected_to new_session_url
  end

  test "rate limits repeated confirmation email resends" do
    10.times { post email_confirmations_url, params: { email_address: "nobody@example.com" } }

    post email_confirmations_url, params: { email_address: "nobody@example.com" }

    assert_redirected_to new_email_confirmation_url
    assert_equal I18n.t("email_confirmations.rate_limit"), flash[:alert]
  end

  test "show confirms the account with a valid token" do
    user = User.create!(name: "Unconf", email_address: "unconf2@example.com", password: "password1234")
    token = user.generate_token_for(:email_confirmation)

    get email_confirmation_url(token)

    assert user.reload.confirmed?
    assert_redirected_to new_session_url
  end

  test "show is idempotent for an already-confirmed account" do
    token = users(:one).generate_token_for(:email_confirmation)
    original = users(:one).confirmed_at

    get email_confirmation_url(token)

    assert_redirected_to new_session_url
    assert_equal original.to_i, users(:one).reload.confirmed_at.to_i
  end

  test "show rejects an invalid token" do
    get email_confirmation_url("not-a-token")

    assert_redirected_to new_email_confirmation_url
  end

  test "an unconfirmed user cannot sign in" do
    user = User.create!(name: "Unconf", email_address: "unconf3@example.com", password: "password1234")

    post session_url, params: { email_address: user.email_address, password: "password1234" }

    assert_redirected_to new_session_url
    assert_not cookies[:session_id].present?
  end
end
