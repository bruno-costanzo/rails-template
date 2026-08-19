require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  test "new document form renders the Lexxy editor" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path
    visit new_document_url
    assert_selector "lexxy-editor"
  end
end
