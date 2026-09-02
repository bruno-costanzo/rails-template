class ModelsController < ApplicationController
  include SuperadminAuthentication

  allow_unauthenticated_access

  def index
    @models = available_chat_models
  end

  def show
    @model = Model.find(params[:id])
  end

  def refresh
    Model.refresh!
    redirect_to models_path, notice: t("models.refresh.notice")
  end
end
