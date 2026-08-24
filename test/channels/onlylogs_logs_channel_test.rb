require "test_helper"

class OnlylogsLogsChannelTest < ActionCable::Channel::TestCase
  tests Onlylogs::LogsChannel

  setup do
    @log_path = Rails.root.join("storage/logs/production.log")
    FileUtils.mkdir_p(@log_path.dirname)
    File.write(@log_path, "SECRET-PRODUCTION-LINE\n")
  end

  teardown do
    FileUtils.rm_f(@log_path)
  end

  test "blank file_path does not stream the default log file" do
    subscribe

    assert subscription.confirmed?

    perform :initialize_watcher, file_path: "", mode: "static"

    assert transmissions.none? { |transmission| transmission.to_s.include?("SECRET-PRODUCTION-LINE") }
    assert transmissions.none? { |transmission| transmission["action"] == "append_logs" }
  end
end
