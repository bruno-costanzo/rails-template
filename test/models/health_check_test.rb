require "test_helper"

class HealthCheckTest < ActiveSupport::TestCase
  test "reports the database as alive" do
    assert_equal({ database: true }, HealthCheck.call)
  end

  test "skips the jobs check when the app does not run Solid Queue" do
    assert_not_includes HealthCheck.call.keys, :jobs
  end

  test "reports the jobs check as failed when the queue cannot be reached" do
    with_solid_queue do
      assert_equal({ database: true, jobs: false }, HealthCheck.call)
    end
  end

  private

  def with_solid_queue
    previous = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue
    yield
  ensure
    ActiveJob::Base.queue_adapter = previous
  end
end
