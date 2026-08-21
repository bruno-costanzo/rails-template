require "test_helper"

class ModelsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get models_url
    assert_redirected_to new_session_url
  end

  test "lists the available chat models" do
    sign_in_as users(:one)
    get models_url
    assert_response :success
  end

  test "shows a model" do
    sign_in_as users(:one)
    model = Model.create!(model_id: "gpt-4o-mini", name: "GPT-4o mini", provider: "openai")
    get model_url(model)
    assert_response :success
  end

  test "refreshes the model registry" do
    sign_in_as users(:one)

    refreshed = false
    Model.define_singleton_method(:refresh!) { refreshed = true }
    begin
      post refresh_models_url
    ensure
      Model.singleton_class.send(:remove_method, :refresh!)
    end

    assert refreshed
    assert_redirected_to models_path
  end
end
