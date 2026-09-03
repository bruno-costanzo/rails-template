class DocsController < ApplicationController
  include SuperadminAuthentication

  allow_unauthenticated_access

  layout "docs"

  before_action :set_docs

  def index
  end

  def show
    @doc = Doc.find(params[:slug])
  end

  private
    def set_docs
      @docs = Doc.all
    end
end
