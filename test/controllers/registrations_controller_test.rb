require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the sign up form" do
    get new_registration_url
    assert_response :success
  end

  test "creates an unconfirmed user, sends a confirmation email, and does not start a session" do
    assert_difference("User.count") do
      assert_enqueued_emails 1 do
        post registration_url, params: { user: { name: "Joan Clarke", email_address: "joan@example.com",
          password: "password1234", password_confirmation: "password1234" } }
      end
    end

    assert_not User.find_by(email_address: "joan@example.com").confirmed?
    assert_redirected_to new_session_url
    assert_not cookies[:session_id].present?
  end

  test "re-renders on invalid data" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: "", email_address: "bad", password: "x", password_confirmation: "y" } }
    end
    assert_response :unprocessable_entity
  end
end
