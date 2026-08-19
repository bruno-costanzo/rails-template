class DocumentsController < ApplicationController
  def index
    @documents = Current.user.documents.order(updated_at: :desc)
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
      redirect_to @document, notice: "Document created"
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
      redirect_to @document, notice: "Document updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user.documents.find(params[:id]).destroy
    redirect_to documents_url, notice: "Document deleted"
  end

  private

  def document_params
    params.expect(document: [ :title, :content ])
  end
end
