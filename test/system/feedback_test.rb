require "application_system_test_case"

class FeedbackTest < ApplicationSystemTestCase
  test "submitting feedback with a photo persists it and shows a success toast" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path

    visit new_feedback_url
    fill_in "What's on your mind?", with: "The chat page is slow"
    attach_file "Attach screenshots (optional)", Rails.root.join("test/fixtures/files/avatar.png")
    click_button "Send feedback"

    assert_selector ".toast .alert.alert-success", text: "Thanks for the feedback!"
    feedback = Feedback.last
    assert_equal "The chat page is slow", feedback.message
    assert_equal 1, feedback.photos.count
  end
end
