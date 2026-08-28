require "test_helper"

class DevelopmentProcessesTest < ActiveSupport::TestCase
  test "development runs the job supervisor in its own process" do
    assert_includes Rails.root.join("Procfile.dev").read, "bin/jobs"
  end

  test "development broadcasts across processes, because its jobs run in another one" do
    adapter = YAML.load_file(Rails.root.join("config/cable.yml"), aliases: true).dig("development", "adapter")

    assert_not_equal "async", adapter,
      "Action Cable's async adapter only delivers within one process. Development runs jobs in a separate " \
      "process (see Procfile.dev), so a job that broadcasts — a streamed chat reply, for instance — would " \
      "never reach the browser, and the message would only appear on reload."
  end
end
