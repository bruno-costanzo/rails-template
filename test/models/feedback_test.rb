require "test_helper"

class FeedbackTest < ActiveSupport::TestCase
  test "requires a message" do
    feedback = users(:one).feedbacks.build(message: "")
    assert_not feedback.valid?
    assert_includes feedback.errors[:message], "can't be blank"
  end

  test "is valid with a user and a message" do
    feedback = users(:one).feedbacks.build(message: "The chat page is slow")
    assert feedback.valid?
  end

  test "enqueues CreateFeedbackIssueJob after create" do
    assert_enqueued_with(job: CreateFeedbackIssueJob) do
      users(:one).feedbacks.create!(message: "The chat page is slow")
    end
  end
end
