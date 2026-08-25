class DataExportsController < ApplicationController
  def create
    DataExportJob.perform_later(Current.user)
    redirect_to edit_profile_path, notice: t(".notice")
  end

  def show
    if Current.user.data_export.attached?
      redirect_to rails_blob_path(Current.user.data_export, disposition: "attachment")
    else
      redirect_to edit_profile_path, notice: t(".pending")
    end
  end
end
