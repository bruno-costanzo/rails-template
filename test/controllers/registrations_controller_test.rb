require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the sign up form" do
    get new_registration_url
    assert_response :success
  end

  test "creates a user and starts a session" do
    assert_difference("User.count") do
      post registration_url, params: { user: { name: "Joan Clarke", email_address: "joan@example.com",
        password: "password1234", password_confirmation: "password1234" } }
    end
    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "re-renders on invalid data" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: "", email_address: "bad", password: "x", password_confirmation: "y" } }
    end
    assert_response :unprocessable_entity
  end
end
