require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home is public and renders meta title" do
    get root_url
    assert_response :success
    assert_select "title", "Home | CharcoTemplate"
  end
end
