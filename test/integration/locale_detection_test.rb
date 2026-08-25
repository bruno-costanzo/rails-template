require "test_helper"

class LocaleDetectionTest < ActionDispatch::IntegrationTest
  test "serves Spanish when the browser prefers it" do
    get new_session_url, headers: { "Accept-Language" => "es-ES,es;q=0.9,en;q=0.8" }

    assert_select "h1", "Iniciar sesión"
  end

  test "serves English when the browser prefers it" do
    get new_session_url, headers: { "Accept-Language" => "en-US,en;q=0.9,es;q=0.8" }

    assert_select "h1", "Sign in"
  end

  test "falls back to the default locale (Spanish) without an Accept-Language header" do
    get new_session_url

    assert_select "h1", "Iniciar sesión"
  end
end
