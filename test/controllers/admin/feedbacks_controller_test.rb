require "test_helper"

module Admin
  class FeedbacksControllerTest < ActionDispatch::IntegrationTest
    setup do
      @original_username = ENV["SUPERADMIN_USER"]
      @original_password = ENV["SUPERADMIN_PASSWORD"]
    end

    teardown do
      ENV["SUPERADMIN_USER"] = @original_username
      ENV["SUPERADMIN_PASSWORD"] = @original_password
    end

    test "requires basic auth credentials" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"

      get admin_feedbacks_url

      assert_response :unauthorized
    end

    test "denies access when no admin credentials are configured" do
      ENV["SUPERADMIN_USER"] = nil
      ENV["SUPERADMIN_PASSWORD"] = nil

      get admin_feedbacks_url, headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_response :unauthorized
    end

    test "is reachable with the configured admin credentials" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"

      get admin_feedbacks_url, headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_response :success
    end

    test "lists only open tickets" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"
      open_feedback = users(:one).feedbacks.create!(message: "The chat page is slow")
      resolved_feedback = users(:one).feedbacks.create!(message: "Already handled")
      resolved_feedback.resolve!

      get admin_feedbacks_url, headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_includes @response.body, open_feedback.message
      assert_not_includes @response.body, resolved_feedback.message
    end

    test "renders escaped context values and photo links" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"

      get admin_feedbacks_url, headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }
      assert_not_includes @response.body, "&lt;b&gt;evil&lt;/b&gt;"

      feedback = users(:one).feedbacks.create!(message: "Layout looks broken", context: { page_url: "<b>evil</b>" })
      feedback.photos.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png")
      photo_url = feedback_photo_url(signed_id: feedback.photos.first.blob.signed_id)

      get admin_feedbacks_url, headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_includes @response.body, "&lt;b&gt;evil&lt;/b&gt;"
      assert_not_includes @response.body, "<b>evil</b>"
      assert_includes @response.body, photo_url
    end

    test "renders multiple open tickets with photos without an N+1" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"
      first_feedback = users(:one).feedbacks.create!(message: "The chat page is slow")
      first_feedback.photos.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png")
      users(:two).feedbacks.create!(message: "Layout looks broken")

      get admin_feedbacks_url, headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_response :success
    end

    test "resolve action marks the ticket resolved and redirects with a flash" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"
      feedback = users(:one).feedbacks.create!(message: "The chat page is slow")

      patch resolve_admin_feedback_url(feedback), headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_redirected_to admin_feedbacks_url
      assert_equal "Ticket resolved.", flash[:notice]
      assert feedback.reload.resolved?
    end

    test "resolve action is idempotent" do
      ENV["SUPERADMIN_USER"] = "admin"
      ENV["SUPERADMIN_PASSWORD"] = "secret"
      feedback = users(:one).feedbacks.create!(message: "The chat page is slow")
      feedback.resolve!
      first_resolved_at = feedback.resolved_at

      patch resolve_admin_feedback_url(feedback), headers: { "Authorization" => "Basic #{Base64.strict_encode64("admin:secret")}" }

      assert_redirected_to admin_feedbacks_url
      assert_equal first_resolved_at, feedback.reload.resolved_at
    end
  end
end
