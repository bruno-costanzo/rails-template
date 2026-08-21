require "test_helper"

class GithubIssuesTest < ActiveSupport::TestCase
  setup do
    @original_token = ENV["GITHUB_ISSUES_TOKEN"]
    @original_repo = ENV["GITHUB_ISSUES_REPO"]
  end

  teardown do
    ENV["GITHUB_ISSUES_TOKEN"] = @original_token
    ENV["GITHUB_ISSUES_REPO"] = @original_repo
  end

  test "is not configured when the token is blank" do
    ENV["GITHUB_ISSUES_TOKEN"] = nil
    ENV["GITHUB_ISSUES_REPO"] = "acme/app"
    assert_not GithubIssues.configured?
  end

  test "is not configured when the repo is blank" do
    ENV["GITHUB_ISSUES_TOKEN"] = "fine-grained-token"
    ENV["GITHUB_ISSUES_REPO"] = nil
    assert_not GithubIssues.configured?
  end

  test "is configured when both the token and repo are present" do
    ENV["GITHUB_ISSUES_TOKEN"] = "fine-grained-token"
    ENV["GITHUB_ISSUES_REPO"] = "acme/app"
    assert GithubIssues.configured?
  end

  test "posts an issue to the GitHub REST API with the expected headers and body" do
    ENV["GITHUB_ISSUES_TOKEN"] = "fine-grained-token"
    ENV["GITHUB_ISSUES_REPO"] = "acme/app"

    request = stub_request(:post, "https://api.github.com/repos/acme/app/issues")
      .with(
        headers: {
          "Authorization" => "Bearer fine-grained-token",
          "Accept" => "application/vnd.github+json",
          "X-GitHub-Api-Version" => "2022-11-28",
          "Content-Type" => "application/json"
        },
        body: { title: "Slow chat page", body: "Details here", labels: [ "feedback" ] }.to_json
      )
      .to_return(status: 201, headers: { "Content-Type" => "application/json" }, body: { number: 42 }.to_json)

    GithubIssues.create(title: "Slow chat page", body: "Details here", labels: [ "feedback" ])

    assert_requested request
  end

  test "raises when GitHub responds with a non-2xx status" do
    ENV["GITHUB_ISSUES_TOKEN"] = "fine-grained-token"
    ENV["GITHUB_ISSUES_REPO"] = "acme/app"

    stub_request(:post, "https://api.github.com/repos/acme/app/issues")
      .to_return(status: 401, body: { message: "Bad credentials" }.to_json)

    assert_raises(GithubIssues::Error) do
      GithubIssues.create(title: "Slow chat page", body: "Details here", labels: [ "feedback" ])
    end
  end
end
