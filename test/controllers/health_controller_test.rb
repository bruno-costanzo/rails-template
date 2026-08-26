require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "reports ok when every check passes" do
    get health_url

    assert_response :success
    assert_equal({ "status" => "ok", "checks" => { "database" => "ok" } }, response.parsed_body)
  end

  test "reports unavailable when a check fails" do
    previous = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue

    get health_url

    assert_response :service_unavailable
    assert_equal({ "status" => "error", "checks" => { "database" => "ok", "jobs" => "error" } }, response.parsed_body)
  ensure
    ActiveJob::Base.queue_adapter = previous
  end

  test "does not require a signed in session" do
    get health_url

    assert_response :success
  end
end
