require "test_helper"

class PunditWiringTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  class DocumentsController < ApplicationController
    def index
      render json: policy_scope(Document).map(&:id)
    end

    def show
      authorize Document.find(params[:id])
      head :ok
    end
  end

  with_routing do |routes|
    routes.draw do
      root "pages#home"
      resource :session, only: :create
      get "pundit_documents" => "pundit_wiring_test/documents#index"
      get "pundit_documents/:id" => "pundit_wiring_test/documents#show"
    end
  end

  test "authorize permits the owner" do
    sign_in_as users(:one)

    get "/pundit_documents/#{documents(:one).id}"

    assert_response :ok
  end

  test "authorize denies another user and redirects with an alert" do
    sign_in_as users(:two)

    get "/pundit_documents/#{documents(:one).id}"

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "policy_scope filters records to the signed in user" do
    sign_in_as users(:one)

    get "/pundit_documents"

    assert_equal [ documents(:one).id ], response.parsed_body
  end
end
