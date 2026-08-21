require "test_helper"

class FeedbackPhotosControllerTest < ActionDispatch::IntegrationTest
  test "redirects to the blob for a photo attached to a feedback, without requiring authentication" do
    feedback = users(:one).feedbacks.create!(message: "Broken layout")
    feedback.photos.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png")
    signed_id = feedback.photos.first.blob.signed_id

    get feedback_photo_url(signed_id: signed_id)

    assert_response :redirect
    assert_match %r{\A https?://}x, response.headers["Location"]
  end

  test "404s for a signed id that does not resolve to a blob" do
    get feedback_photo_url(signed_id: "not-a-real-signed-id")

    assert_response :not_found
  end

  test "404s for a valid signed id that is not attached to a feedback" do
    user = users(:one)
    user.avatar.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png")
    signed_id = user.avatar.blob.signed_id

    get feedback_photo_url(signed_id: signed_id)

    assert_response :not_found
  end
end
