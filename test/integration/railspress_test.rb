require "test_helper"

class RailspressTest < ActionDispatch::IntegrationTest
  setup do
    @orig_user = ENV["SUPERADMIN_USER"]
    @orig_pass = ENV["SUPERADMIN_PASSWORD"]
    ENV["SUPERADMIN_USER"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "secret"
  end

  teardown do
    ENV["SUPERADMIN_USER"] = @orig_user
    ENV["SUPERADMIN_PASSWORD"] = @orig_pass
  end

  def superadmin_headers
    { "Authorization" => "Basic #{Base64.strict_encode64("superadmin:secret")}" }
  end

  test "admin requires superadmin auth" do
    get "/railspress/admin"

    assert_response :unauthorized
  end

  test "admin denies access when no credentials are configured" do
    ENV["SUPERADMIN_USER"] = nil
    ENV["SUPERADMIN_PASSWORD"] = nil

    get "/railspress/admin", headers: superadmin_headers

    assert_response :unauthorized
  end

  test "admin dashboard renders with superadmin credentials" do
    get "/railspress/admin", headers: superadmin_headers

    assert_response :success
  end
end
