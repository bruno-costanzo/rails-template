require "test_helper"

class DataExportTest < ActiveSupport::TestCase
  test "packages the user's records and files into a zip without sensitive columns" do
    user = users(:one)
    user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")
    chat = user.chats.create!(model: "gpt-4o-mini")
    document = user.documents.create!(title: "My notes")
    feedback = user.feedbacks.create!(message: "Nice app")
    feedback.photos.attach(io: File.open(file_fixture("avatar.png")), filename: "shot.png", content_type: "image/png")

    entries = zip_entries(DataExport.new(user).to_zip)

    data = JSON.parse(entries["data.json"])
    assert_equal user.email_address, data["user"]["email_address"]
    assert_not data["user"].key?("password_digest")
    assert_includes data["chats"].map { |record| record["id"] }, chat.id
    assert_includes data["documents"].map { |record| record["id"] }, document.id
    assert_not data["documents"].find { |record| record["id"] == document.id }.key?("embedding")
    assert_includes data["feedbacks"].map { |record| record["id"] }, feedback.id

    assert_includes entries.keys, "files/user/avatar/avatar.png"
    assert_includes entries.keys, "files/feedbacks/#{feedback.id}/photos/shot.png"
  end

  private

  def zip_entries(bytes)
    {}.tap do |entries|
      Zip::File.open_buffer(StringIO.new(bytes)) do |zip|
        zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
      end
    end
  end
end
