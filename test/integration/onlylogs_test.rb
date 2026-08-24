require "test_helper"

class OnlylogsTest < ActionDispatch::IntegrationTest
  setup do
    @original_user = ENV["ONLYLOGS_BASIC_AUTH_USER"]
    @original_password = ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"]
  end

  teardown do
    ENV["ONLYLOGS_BASIC_AUTH_USER"] = @original_user
    ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"] = @original_password
  end

  test "requires basic auth credentials" do
    ENV["ONLYLOGS_BASIC_AUTH_USER"] = "logs"
    ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"] = "secret"

    get "/onlylogs"

    assert_response :unauthorized
  end

  test "denies access with wrong credentials" do
    ENV["ONLYLOGS_BASIC_AUTH_USER"] = "logs"
    ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"] = "secret"

    get "/onlylogs", headers: { "Authorization" => "Basic #{Base64.strict_encode64("logs:wrong")}" }

    assert_response :unauthorized
  end

  test "denies access when no credentials are configured" do
    ENV["ONLYLOGS_BASIC_AUTH_USER"] = nil
    ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"] = nil

    get "/onlylogs", headers: { "Authorization" => "Basic #{Base64.strict_encode64("logs:secret")}" }

    assert_response :unauthorized
  end

  test "is reachable with the configured credentials" do
    ENV["ONLYLOGS_BASIC_AUTH_USER"] = "logs"
    ENV["ONLYLOGS_BASIC_AUTH_PASSWORD"] = "secret"

    get "/onlylogs", headers: { "Authorization" => "Basic #{Base64.strict_encode64("logs:secret")}" }

    assert_response :success
  end
end
