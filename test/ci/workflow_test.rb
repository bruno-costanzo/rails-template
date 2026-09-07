require "test_helper"

class CiWorkflowTest < ActiveSupport::TestCase
  WORKFLOW = Rails.root.join(".github/workflows/ci.yml")
  DEPLOY_KEY = "CHARCO_MOBILE_DEPLOY_KEY".freeze
  SSH_AGENT = "webfactory/ssh-agent".freeze

  test "the step that loads the mobile deploy key is skipped when the secret is absent" do
    assert_equal "env.#{DEPLOY_KEY} != ''", ssh_agent_step["if"],
      "an app whose repository never registered #{DEPLOY_KEY} gets an empty string here, and the action fails the step on an empty key"
  end

  test "the deploy key reaches the step through the job's environment, the only context a step condition can read" do
    assert_equal "${{ secrets.#{DEPLOY_KEY} }}", job.dig("env", DEPLOY_KEY)
    assert_equal "${{ env.#{DEPLOY_KEY} }}", ssh_agent_step.dig("with", "ssh-private-key")
  end

  test "no step condition reads the secrets context, which GitHub does not expose there" do
    conditions = steps.filter_map { |step| step["if"] }

    assert_empty conditions.grep(/secrets\./),
      "a condition on secrets.* is always false, so the step it guards never runs"
  end

  private

  def workflow
    @workflow ||= YAML.safe_load(WORKFLOW.read)
  end

  def job
    workflow.dig("jobs", "ci")
  end

  def steps
    job["steps"]
  end

  def ssh_agent_step
    steps.find { |step| step["uses"].to_s.start_with?(SSH_AGENT) }
  end
end
