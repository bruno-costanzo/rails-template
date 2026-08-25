class DataExportsController < ApplicationController
  def create
    DataExportJob.perform_later(Current.user)
    redirect_to edit_profile_path, notice: t(".notice")
  end

  def show
    export = Current.user.data_export

    if export.attached? && fresh?(export)
      redirect_to rails_blob_path(export, disposition: "attachment")
    elsif export.attached?
      export.purge_later
      redirect_to edit_profile_path, notice: t(".expired")
    else
      redirect_to edit_profile_path, notice: t(".pending")
    end
  end

  private

  def fresh?(export)
    export.attachment.created_at > DataExport::RETENTION.ago
  end
end
