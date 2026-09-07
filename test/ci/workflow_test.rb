require "test_helper"

class CiWorkflowTest < ActiveSupport::TestCase
  WORKFLOW = Rails.root.join(".github/workflows/ci.yml")
  DEPLOY_KEY = "CHARCO_MOBILE_DEPLOY_KEY".freeze
  SSH_AGENT = "webfactory/ssh-agent".freeze
  PROBE = "mobile_deploy_key".freeze

  test "the step that loads the mobile deploy key is skipped when the secret is absent" do
    assert_equal "steps.#{PROBE}.outputs.present == 'true'", ssh_agent_step["if"],
      "an app whose repository never registered #{DEPLOY_KEY} gets an empty string here, and the action fails the step on an empty key"
  end

  test "the step condition reads a probe output, the only shape a condition can see a secret through" do
    assert_equal "echo \"present=${{ secrets.#{DEPLOY_KEY} != '' }}\" >> $GITHUB_OUTPUT", probe_step["run"]
    assert_equal "${{ secrets.#{DEPLOY_KEY} }}", ssh_agent_step.dig("with", "ssh-private-key")
  end

  test "the deploy key itself never reaches the environment of the steps that do not need it" do
    assert_nil job.dig("env", DEPLOY_KEY),
      "a job-level environment hands the private key to every step of the run, including the ones that only need to know whether it exists"
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

  def probe_step
    steps.find { |step| step["id"] == PROBE }
  end

  def ssh_agent_step
    steps.find { |step| step["uses"].to_s.start_with?(SSH_AGENT) }
  end
end
