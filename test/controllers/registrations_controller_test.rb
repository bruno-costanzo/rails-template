require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

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

  test "destroy deletes the account and its data with the exact phrase and password" do
    user = users(:one)
    chat = user.chats.create!(model: "gpt-4o-mini")
    sign_in_as user

    assert_difference("User.count", -1) do
      delete registration_url, params: { confirmation: I18n.t("registrations.destroy.confirmation_phrase"), password: "password" }
    end

    assert_redirected_to new_session_url
    assert_nil User.find_by(id: user.id)
    assert_nil Chat.find_by(id: chat.id)
    assert_not cookies[:session_id].present?
  end

  test "destroy is rejected with the wrong confirmation phrase" do
    sign_in_as users(:one)

    assert_no_difference("User.count") do
      delete registration_url, params: { confirmation: "nope", password: "password" }
    end

    assert_redirected_to edit_profile_url
  end

  test "destroy is rejected with the wrong password" do
    sign_in_as users(:one)

    assert_no_difference("User.count") do
      delete registration_url, params: { confirmation: I18n.t("registrations.destroy.confirmation_phrase"), password: "wrong" }
    end

    assert_redirected_to edit_profile_url
  end

  test "destroy requires authentication" do
    assert_no_difference("User.count") do
      delete registration_url, params: { confirmation: I18n.t("registrations.destroy.confirmation_phrase"), password: "password" }
    end

    assert_redirected_to new_session_url
  end
end
