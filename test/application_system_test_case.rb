ENV["SKIP_COVERAGE"] ||= "1"
require "test_helper"

Capybara.default_max_wait_time = 8
Capybara.server = :puma, { Threads: "2:8" }

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  ActiveJob::Base.queue_adapter = :inline

  def assert_turbo_ready
    assert_selector "body[data-turbo-ready]"
  end

  def sign_in_via_browser(user)
    visit new_session_url
    assert_turbo_ready
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_current_path root_path
  end
end
