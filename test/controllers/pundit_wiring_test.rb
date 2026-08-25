require "test_helper"

class PunditWiringTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  class RecordsController < ApplicationController
    def index
      render json: policy_scope(PunditTestRecord).map { |record| record.user.id }
    end

    def show
      authorize PunditTestRecord.new(User.find(params[:id]))
      head :ok
    end
  end

  with_routing do |routes|
    routes.draw do
      root "pages#home"
      resource :session, only: :create
      get "pundit_records" => "pundit_wiring_test/records#index"
      get "pundit_records/:id" => "pundit_wiring_test/records#show"
    end
  end

  test "authorize permits the owner" do
    sign_in_as users(:one)

    get "/pundit_records/#{users(:one).id}"

    assert_response :ok
  end

  test "authorize denies another user and redirects with an alert" do
    sign_in_as users(:two)

    get "/pundit_records/#{users(:one).id}"

    assert_redirected_to root_path
    assert_equal I18n.t("authorization.not_authorized"), flash[:alert]
  end

  test "policy_scope filters records to the signed in user" do
    sign_in_as users(:one)

    get "/pundit_records"

    assert_equal [ users(:one).id ], response.parsed_body
  end
end
