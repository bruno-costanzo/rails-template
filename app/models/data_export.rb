require "zip"

class DataExport
  EXCLUDED_COLUMNS = {
    "User" => %w[password_digest],
    "Document" => %w[embedding]
  }.freeze

  EXCLUDED_ATTACHMENTS = %w[data_export].freeze

  def initialize(user)
    @user = user
  end

  def to_zip
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("data.json")
      zip.write(JSON.pretty_generate(data))
      files.each do |path, bytes|
        zip.put_next_entry(path)
        zip.write(bytes)
      end
    end.tap(&:rewind).read
  end

  private

  attr_reader :user

  def data
    { "user" => serialize(user) }.merge(associations_data)
  end

  def associations_data
    exported_associations.to_h do |reflection|
      [ reflection.name.to_s, user.public_send(reflection.name).map { |record| serialize(record) } ]
    end
  end

  def exported_associations
    User.reflect_on_all_associations.select do |reflection|
      reflection.options[:dependent] == :destroy && domain_association?(reflection)
    end
  end

  def domain_association?(reflection)
    !reflection.klass.name.start_with?("ActiveStorage::", "ActionText::")
  end

  def serialize(record)
    record.as_json(except: EXCLUDED_COLUMNS[record.class.name])
  end

  def files
    entries = attachments_for("user", user)
    exported_associations.each do |reflection|
      user.public_send(reflection.name).each do |record|
        entries.concat(attachments_for("#{reflection.name}/#{record.id}", record))
      end
    end
    entries
  end

  def attachments_for(prefix, record)
    ActiveStorage::Attachment.where(record: record).where.not(name: EXCLUDED_ATTACHMENTS).includes(:blob).map do |attachment|
      [ "files/#{prefix}/#{attachment.name}/#{attachment.blob.filename}", attachment.blob.download ]
    end
  end
end
