unless ENV["SKIP_COVERAGE"]
  require "simplecov"
  SimpleCov.start "rails" do
    enable_coverage :branch
    add_filter "app/madmin"
    add_filter "app/controllers/madmin"
    add_filter "app/controllers/concerns/superadmin_authentication"
    add_filter "app/controllers/concerns/railspress_admin_auth"
    minimum_coverage line: 100, branch: 100
  end
end

ENV["RAILS_ENV"] ||= "test"
ENV["OPENAI_API_KEY"] ||= "test-key"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

Dir[Rails.root.join("test/test_helpers/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("test/notifiers/*.rb")].reject { |f| f.end_with?("_test.rb") }.each { |f| require f }
Dir[Rails.root.join("test/policies/*.rb")].reject { |f| f.end_with?("_test.rb") }.each { |f| require f }

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    def before_setup
      Bullet.start_request
      super
    end

    def after_teardown
      super
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end

    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}" if defined?(SimpleCov)
    end

    parallelize_teardown do |worker|
      SimpleCov.result if defined?(SimpleCov)
    end

    fixtures :all
  end
end
