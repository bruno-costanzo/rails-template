class DataExportJob < ApplicationJob
  queue_as :default

  def perform(user)
    zip = DataExport.new(user).to_zip
    user.data_export.attach(io: StringIO.new(zip), filename: "data-export.zip", content_type: "application/zip")
    DataExportMailer.ready(user).deliver_later
  end
end
