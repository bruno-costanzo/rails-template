require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home is public and renders meta title" do
    get root_url
    assert_response :success
    assert_select "title", "#{I18n.t('pages.home.meta_title')} | #{Rails.application.class.module_parent_name}"
  end
end
