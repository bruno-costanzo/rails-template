module QueryCountHelper
  def count_queries(matching:)
    count = 0
    callback = lambda do |*, payload|
      next if payload[:name] == "SCHEMA"
      count += 1 if payload[:sql].to_s.match?(matching)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end
end
