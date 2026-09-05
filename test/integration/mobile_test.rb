require "test_helper"

class MobileTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  NATIVE = { "User-Agent" => "Mozilla/5.0 (iPhone) Charco Mobile iOS/1.0/1 iOS/26.0/23A1 CharcoMobile/#{CharcoMobile::VERSION}" }.freeze

  test "a signed-out page carries an empty identity and no tabs, and keeps the web navbar" do
    get root_url, headers: NATIVE

    assert_select "[data-native-identity='']"
    assert_select "[data-native-tabs]", false
    assert_select "[data-native-badge]", false
    assert_select ".navbar", false
    assert_select "main.native-inset"
  end

  test "a browser keeps the web navbar and never sees the native inset" do
    get root_url

    assert_select ".navbar"
    assert_select "main.mt-28"
    assert_select "[data-native-identity='']"
  end

  test "a signed-in page carries the identity, the tab bar and the badge" do
    sign_in_as users(:one)
    get root_url, headers: NATIVE

    token = css_select("[data-native-identity]").first["data-native-identity"]
    assert_match(/\A\h{16}\z/, token)
    assert_select "[data-native-tabs]"
    assert_select "[data-native-badge][data-native-badge-home='0'][data-native-badge-tab='0']"
  end

  test "a notice toasts in the app and stays a banner in the browser" do
    sign_in_as users(:one)

    patch profile_url, params: { user: { name: "Ada" } }
    follow_redirect!
    assert_select "[data-native-toast]", false
    assert_select "#flash .alert-success"

    patch profile_url, params: { user: { name: "Ada" } }, headers: NATIVE
    get response.location, headers: NATIVE
    assert_select "[data-native-toast]"
    assert_select "#flash .alert-success", false
  end

  test "form pages are marked so the app skips them on the way back" do
    get new_session_url
    assert_select "[data-native-form]"

    get new_registration_url
    assert_select "[data-native-form]"
  end

  test "the config document carries every tab with its title in both locales" do
    get "/native/config"

    assert_response :success
    tabs = response.parsed_body["tabs"]
    assert_equal %w[home chats documents notifications profile], tabs.map { |tab| tab["key"] }
    assert_equal({ "es" => I18n.t("charco_mobile.tabs.home.title", locale: :es), "en" => I18n.t("charco_mobile.tabs.home.title", locale: :en) }, tabs.first["titles"])
    assert_equal "house", tabs.first["icon"]
    assert_equal [ "/profile", "/active_sessions", "/feedback" ], tabs.last["auto_route"]
    assert_equal "normal", response.parsed_body.dig("app", "mode")
    assert_equal "/", response.parsed_body.dig("app", "entry_path")
    assert_equal I18n.t("charco_mobile.errors.retry", locale: :es), response.parsed_body.dig("errors", "retry", "es")
  end
end
