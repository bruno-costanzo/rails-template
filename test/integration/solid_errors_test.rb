require "test_helper"

class SolidErrorsTest < ActionDispatch::IntegrationTest
  test "reported errors are persisted as SolidErrors::Error records" do
    assert_difference "SolidErrors::Error.count", 1 do
      Rails.error.report(StandardError.new("boom"), handled: true)
    end
  end

  test "dashboard requires basic auth credentials" do
    get "/errors"

    assert_response :unauthorized
  end

  test "dashboard is reachable with the configured basic auth credentials" do
    username = Rails.application.credentials.dig(:solid_errors, :username) || ENV["SOLID_ERRORS_USERNAME"]
    password = Rails.application.credentials.dig(:solid_errors, :password) || ENV["SOLID_ERRORS_PASSWORD"]

    get "/errors", headers: { "Authorization" => "Basic #{Base64.strict_encode64("#{username}:#{password}")}" }

    assert_response :success
  end
end
