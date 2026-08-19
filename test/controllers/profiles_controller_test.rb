require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get edit_profile_url
    assert_redirected_to new_session_url
  end

  test "updates name and avatar" do
    sign_in_as users(:one)
    patch profile_url, params: { user: { name: "Ada King", avatar: fixture_file_upload("avatar.png", "image/png") } }
    assert_redirected_to edit_profile_url
    assert_equal "Ada King", users(:one).reload.name
    assert users(:one).avatar.attached?
  end

  test "ignores blank password fields" do
    sign_in_as users(:one)
    patch profile_url, params: { user: { name: "Ada King", password: "", password_confirmation: "" } }
    assert_redirected_to edit_profile_url
  end
end
