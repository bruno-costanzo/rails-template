require "test_helper"

class LetterOpenerWebTest < ActionDispatch::IntegrationTest
  test "mount is absent outside development" do
    get "/letter_opener"

    assert_response :not_found
  end
end
