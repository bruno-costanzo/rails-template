require "test_helper"

class CreateFeedbackIssueJobTest < ActiveJob::TestCase
  setup do
    @original_token = ENV["GITHUB_ISSUES_TOKEN"]
    @original_repo = ENV["GITHUB_ISSUES_REPO"]
  end

  teardown do
    ENV["GITHUB_ISSUES_TOKEN"] = @original_token
    ENV["GITHUB_ISSUES_REPO"] = @original_repo
  end

  test "does nothing when GithubIssues is not configured" do
    ENV["GITHUB_ISSUES_TOKEN"] = nil
    ENV["GITHUB_ISSUES_REPO"] = nil
    feedback = users(:one).feedbacks.create!(message: "Broken layout")

    CreateFeedbackIssueJob.perform_now(feedback)

    assert_not_requested :post, "https://api.github.com/repos/acme/app/issues"
  end

  test "creates a GitHub issue with the message, user email, app context and photo links" do
    ENV["GITHUB_ISSUES_TOKEN"] = "fine-grained-token"
    ENV["GITHUB_ISSUES_REPO"] = "acme/app"

    feedback = users(:one).feedbacks.create!(message: "Broken layout")
    feedback.photos.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png")
    photo_url = "http://example.com/feedback/photos/#{feedback.photos.first.blob.signed_id}"

    request = stub_request(:post, "https://api.github.com/repos/acme/app/issues")
      .with { |req|
        payload = JSON.parse(req.body)
        payload["title"] == "Feedback from ada@example.com" &&
          payload["labels"] == [ "feedback" ] &&
          payload["body"].include?("Broken layout") &&
          payload["body"].include?("ada@example.com") &&
          payload["body"].include?(photo_url)
      }
      .to_return(status: 201, headers: { "Content-Type" => "application/json" }, body: { number: 1 }.to_json)

    CreateFeedbackIssueJob.perform_now(feedback)

    assert_requested request
  end

  test "does not raise when there are no photos" do
    ENV["GITHUB_ISSUES_TOKEN"] = "fine-grained-token"
    ENV["GITHUB_ISSUES_REPO"] = "acme/app"

    feedback = users(:one).feedbacks.create!(message: "Broken layout")

    request = stub_request(:post, "https://api.github.com/repos/acme/app/issues")
      .to_return(status: 201, headers: { "Content-Type" => "application/json" }, body: { number: 1 }.to_json)

    CreateFeedbackIssueJob.perform_now(feedback)

    assert_requested request
  end
end
