require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get documents_url
    assert_redirected_to new_session_url
  end

  test "creates a document with rich content" do
    sign_in_as users(:one)
    assert_difference("Document.count") do
      post documents_url, params: { document: { title: "Kamal notes", content: "<p>Deploy with <strong>Kamal</strong></p>" } }
    end
    document = Document.last
    assert_equal users(:one), document.user
    assert_includes document.content.to_plain_text, "Deploy with Kamal"
  end

  test "does not show another user's document" do
    sign_in_as users(:one)
    other = users(:two).documents.create!(title: "Private", content: "secret")
    get document_url(other)
    assert_response :not_found
  end
end
