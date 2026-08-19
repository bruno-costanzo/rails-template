require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "serves the manifest publicly" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    assert_equal "CharcoTemplate", JSON.parse(response.body)["name"]
  end

  test "serves the service worker publicly" do
    get pwa_service_worker_path(format: :js)
    assert_response :success
  end
end
