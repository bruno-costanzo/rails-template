require "application_system_test_case"

class FeedbackTest < ApplicationSystemTestCase
  test "submitting feedback with a photo persists it and shows a success toast" do
    sign_in_via_browser(users(:one))

    visit new_feedback_url
    fill_in t("feedbacks.new.message_label"), with: "The chat page is slow"
    attach_file "Attach screenshots (optional)", Rails.root.join("test/fixtures/files/avatar.png")
    click_button t("feedbacks.new.submit")

    assert_selector ".toast .alert.alert-success", text: "Thanks for the feedback!"
    feedback = Feedback.last
    assert_equal "The chat page is slow", feedback.message
    assert_equal 1, feedback.photos.count
  end
end
