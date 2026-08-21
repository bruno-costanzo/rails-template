ENV["SKIP_COVERAGE"] ||= "1"
require "test_helper"

Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Threads: "2:8" }

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  ActiveJob::Base.queue_adapter = :inline
end
