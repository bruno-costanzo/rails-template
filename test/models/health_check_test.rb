require "test_helper"

class HealthCheckTest < ActiveSupport::TestCase
  test "reports the database as alive" do
    assert_equal({ database: true }, HealthCheck.call)
  end

  test "skips the jobs check when the app does not run Solid Queue" do
    assert_not_includes HealthCheck.call.keys, :jobs
  end

  test "reports the jobs check as passing when a supervisor is sending heartbeats" do
    register_supervisor(last_heartbeat_at: Time.current)

    with_solid_queue do
      assert_equal({ database: true, jobs: true }, HealthCheck.call)
    end
  end

  test "reports the jobs check as failing when the supervisor heartbeat went stale" do
    register_supervisor(last_heartbeat_at: (SolidQueue.process_alive_threshold + 1.minute).ago)

    with_solid_queue do
      assert_equal({ database: true, jobs: false }, HealthCheck.call)
    end
  end

  test "reports the jobs check as failing when no supervisor is registered" do
    with_solid_queue do
      assert_equal({ database: true, jobs: false }, HealthCheck.call)
    end
  end

  test "turns a check that raises into a failure instead of an exception" do
    assert_equal false, HealthCheck.new.send(:safely) { raise ActiveRecord::StatementInvalid }
  end

  private

  def register_supervisor(last_heartbeat_at:)
    SolidQueue::Process.create!(kind: "Supervisor(fork)", name: "supervisor-test", pid: 4242, last_heartbeat_at: last_heartbeat_at)
  end

  def with_solid_queue
    previous = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue
    yield
  ensure
    ActiveJob::Base.queue_adapter = previous
  end
end
