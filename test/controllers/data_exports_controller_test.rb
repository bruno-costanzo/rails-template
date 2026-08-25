require "test_helper"

class DataExportsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "create enqueues an export job" do
    sign_in_as users(:one)

    assert_enqueued_with(job: DataExportJob) do
      post data_export_url
    end

    assert_redirected_to edit_profile_url
  end

  test "create requires authentication" do
    assert_no_enqueued_jobs only: DataExportJob do
      post data_export_url
    end

    assert_redirected_to new_session_url
  end

  test "show redirects to the generated export" do
    user = users(:one)
    user.data_export.attach(io: StringIO.new("zip"), filename: "data-export.zip", content_type: "application/zip")
    sign_in_as user

    get data_export_url

    assert_response :redirect
  end

  test "show reports when no export is ready yet" do
    sign_in_as users(:one)

    get data_export_url

    assert_redirected_to edit_profile_url
  end

  test "show requires authentication" do
    get data_export_url

    assert_redirected_to new_session_url
  end
end
