class DocumentsController < ApplicationController
  def index
    @documents = if params[:q].present?
      Document.where(user: Current.user).semantic_search(params[:q])
    else
      Current.user.documents.order(updated_at: :desc)
    end
  end

  def show
    @document = Current.user.documents.find(params[:id])
  end

  def new
    @document = Current.user.documents.build
  end

  def create
    @document = Current.user.documents.build(document_params)
    if @document.save
      redirect_to @document, notice: t("documents.create.notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @document = Current.user.documents.find(params[:id])
  end

  def update
    @document = Current.user.documents.find(params[:id])
    if @document.update(document_params)
      redirect_to @document, notice: t("documents.update.notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user.documents.find(params[:id]).destroy
    redirect_to documents_url, notice: t("documents.destroy.notice")
  end

  private

  def document_params
    params.expect(document: [ :title, :content ])
  end
end
