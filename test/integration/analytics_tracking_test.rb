require "test_helper"

class AnalyticsTrackingTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  BROWSER = { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36" }.freeze

  test "records a visit for an anonymous browser request" do
    assert_difference "Ahoy::Visit.count", 1 do
      get new_session_url, headers: BROWSER
    end

    assert_nil Ahoy::Visit.last.user
  end

  test "attributes the visit to the signed in user through Current.user" do
    user = users(:one)
    sign_in_as(user)

    get documents_url, headers: BROWSER

    assert_equal user, Ahoy::Visit.last.user
  end

  test "attributes the visit on pages that allow unauthenticated access too" do
    user = users(:one)
    sign_in_as(user)

    get root_url, headers: BROWSER

    assert_equal user, Ahoy::Visit.last.user
  end

  test "masks the visitor ip address" do
    get new_session_url, headers: BROWSER

    assert_equal "127.0.0.0", Ahoy::Visit.last.ip
  end

  test "sets no tracking cookie" do
    get new_session_url, headers: BROWSER

    assert_empty cookies[:ahoy_visit].to_s
    assert_empty cookies[:ahoy_visitor].to_s
  end

  test "ignores bots" do
    assert_no_difference "Ahoy::Visit.count" do
      get new_session_url, headers: { "User-Agent" => "Googlebot/2.1 (+http://www.google.com/bot.html)" }
    end
  end
end
