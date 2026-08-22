require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  test "new document form renders the Lexxy editor" do
    sign_in_via_browser(users(:one))
    visit new_document_url
    assert_selector "lexxy-editor"
  end
end
