require "test_helper"

class ModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_username = ENV["SUPERADMIN_USER"]
    @original_password = ENV["SUPERADMIN_PASSWORD"]
  end

  teardown do
    ENV["SUPERADMIN_USER"] = @original_username
    ENV["SUPERADMIN_PASSWORD"] = @original_password
  end

  def superadmin_headers
    { "Authorization" => "Basic #{Base64.strict_encode64("superadmin:secret")}" }
  end

  test "requires basic auth credentials" do
    ENV["SUPERADMIN_USER"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "secret"

    get models_url

    assert_response :unauthorized
  end

  test "denies access when no credentials are configured" do
    ENV["SUPERADMIN_USER"] = nil
    ENV["SUPERADMIN_PASSWORD"] = nil

    get models_url, headers: superadmin_headers

    assert_response :unauthorized
  end

  test "lists the available chat models for the superadmin" do
    ENV["SUPERADMIN_USER"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "secret"

    get models_url, headers: superadmin_headers

    assert_response :success
  end

  test "shows a model for the superadmin" do
    ENV["SUPERADMIN_USER"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "secret"
    model = Model.create!(model_id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai")

    get model_url(model), headers: superadmin_headers

    assert_response :success
  end

  test "refreshes the model registry for the superadmin" do
    ENV["SUPERADMIN_USER"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "secret"

    refreshed = false
    Model.define_singleton_method(:refresh!) { refreshed = true }
    begin
      post refresh_models_url, headers: superadmin_headers
    ensure
      Model.singleton_class.send(:remove_method, :refresh!)
    end

    assert refreshed
    assert_redirected_to models_path
  end
end
