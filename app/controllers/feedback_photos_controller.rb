class FeedbackPhotosController < ApplicationController
  allow_unauthenticated_access

  def show
    blob = ActiveStorage::Blob.find_signed(params[:signed_id])
    raise ActiveRecord::RecordNotFound unless blob && feedback_photo?(blob)

    redirect_to rails_blob_path(blob, disposition: "inline")
  end

  private

  def feedback_photo?(blob)
    blob.attachments.exists?(record_type: "Feedback", name: "photos")
  end
end
