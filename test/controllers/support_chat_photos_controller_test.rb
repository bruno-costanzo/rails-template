require "test_helper"

class SupportChatPhotosControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    post support_chat_photos_url, params: { chat: { pending_photos: [ fixture_file_upload("avatar.png", "image/png") ] } }
    assert_redirected_to new_session_url
  end

  test "attaches an uploaded photo to the user's support chat" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(support: true)

    post support_chat_photos_url, params: { chat: { pending_photos: [ fixture_file_upload("avatar.png", "image/png") ] } }

    assert_response :success
    assert chat.reload.pending_photos.attached?
  end

  test "404s when the user has no support chat yet" do
    sign_in_as users(:one)

    post support_chat_photos_url, params: { chat: { pending_photos: [ fixture_file_upload("avatar.png", "image/png") ] } }

    assert_response :not_found
  end

  test "never attaches the upload to another user's support chat" do
    sign_in_as users(:one)
    users(:one).chats.create!(support: true)
    other_chat = users(:two).chats.create!(support: true)

    post support_chat_photos_url, params: { chat: { pending_photos: [ fixture_file_upload("avatar.png", "image/png") ] } }

    assert_not other_chat.reload.pending_photos.attached?
  end

  test "rejects an invalid photo with a human-friendly error and attaches nothing" do
    sign_in_as users(:one)
    chat = users(:one).chats.create!(support: true)

    post support_chat_photos_url, params: { chat: { pending_photos: [ fixture_file_upload("note.txt", "text/plain") ] } }

    assert_response :unprocessable_entity
    assert_not chat.reload.pending_photos.attached?
    assert_includes @response.body, I18n.t("support_chat_photos.create.upload_error")
  end
end
