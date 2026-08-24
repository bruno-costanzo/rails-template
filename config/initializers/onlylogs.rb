Onlylogs.configure do |config|
  config.disable_basic_authentication = true
  config.parent_controller = "OnlylogsBaseController"
  config.default_log_file_path = ""
  config.log_file_patterns = [ Rails.root.join("storage/logs/production.log") ]
  config.log_file_patterns << Rails.root.join("log/#{Rails.env}.log") unless Rails.env.production?
end
