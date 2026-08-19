require "application_system_test_case"

class LandingTest < ApplicationSystemTestCase
  test "visitor sees hero and call to action" do
    visit root_url
    assert_selector "h1", text: "Build your next idea faster"
    assert_link "Get started"
  end
end
