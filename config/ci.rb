CI.run do
  step "Style: Ruby", "bin/rubocop"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "i18n: Translation health", "bin/i18n-tasks", "health"
  step "Tests: Rails", "bin/rails db:test:prepare test"
  step "Tests: System", "env", "SKIP_COVERAGE=1", "bin/rails", "db:test:prepare", "test:system"
end
