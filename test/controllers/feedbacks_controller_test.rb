require "test_helper"

class FeedbacksControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get new_feedback_url
    assert_redirected_to new_session_url
  end

  test "shows the feedback form" do
    sign_in_as users(:one)
    get new_feedback_url
    assert_response :success
  end

  test "creates feedback scoped to the current user and redirects with a success flash" do
    sign_in_as users(:one)
    assert_difference("Feedback.count") do
      post feedback_url, params: { feedback: { message: "The chat page is slow" } }
    end
    feedback = Feedback.last
    assert_equal users(:one), feedback.user
    assert_redirected_to root_url
    assert_equal "Thanks for the feedback!", flash[:notice]
  end

  test "attaches uploaded photos to the feedback" do
    sign_in_as users(:one)
    photo = fixture_file_upload("test/fixtures/files/avatar.png", "image/png")

    post feedback_url, params: { feedback: { message: "Broken layout", photos: [ photo ] } }

    assert_equal 1, Feedback.last.photos.count
  end

  test "does not create feedback with a blank message" do
    sign_in_as users(:one)
    assert_no_difference("Feedback.count") do
      post feedback_url, params: { feedback: { message: "" } }
    end
    assert_response :unprocessable_entity
  end
end
