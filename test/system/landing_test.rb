require "application_system_test_case"

class LandingTest < ApplicationSystemTestCase
  test "visitor sees hero and call to action" do
    visit root_url
    assert_selector "h1", text: t("pages.home.headline")
    assert_link t("pages.home.start")
  end
end
