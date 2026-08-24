require "test_helper"

class OnlylogsTest < ActionDispatch::IntegrationTest
  setup do
    @original_user = ENV["SUPERADMIN_USER"]
    @original_password = ENV["SUPERADMIN_PASSWORD"]
  end

  teardown do
    ENV["SUPERADMIN_USER"] = @original_user
    ENV["SUPERADMIN_PASSWORD"] = @original_password
  end

  test "requires basic auth credentials" do
    ENV["SUPERADMIN_USER"] = "logs"
    ENV["SUPERADMIN_PASSWORD"] = "secret"

    get "/onlylogs"

    assert_response :unauthorized
  end

  test "denies access with wrong credentials" do
    ENV["SUPERADMIN_USER"] = "logs"
    ENV["SUPERADMIN_PASSWORD"] = "secret"

    get "/onlylogs", headers: { "Authorization" => "Basic #{Base64.strict_encode64("logs:wrong")}" }

    assert_response :unauthorized
  end

  test "denies access when no credentials are configured" do
    ENV["SUPERADMIN_USER"] = nil
    ENV["SUPERADMIN_PASSWORD"] = nil

    get "/onlylogs", headers: { "Authorization" => "Basic #{Base64.strict_encode64("logs:secret")}" }

    assert_response :unauthorized
  end

  test "is reachable with the configured credentials" do
    ENV["SUPERADMIN_USER"] = "logs"
    ENV["SUPERADMIN_PASSWORD"] = "secret"

    get "/onlylogs", headers: { "Authorization" => "Basic #{Base64.strict_encode64("logs:secret")}" }

    assert_response :success
  end
end
