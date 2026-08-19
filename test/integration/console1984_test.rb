require "test_helper"

class Console1984Test < ActiveSupport::TestCase
  test "audit tables exist" do
    assert ActiveRecord::Base.connection.table_exists?("console1984_sessions")
    assert ActiveRecord::Base.connection.table_exists?("console1984_commands")
  end

  test "console protection targets production by default" do
    assert_includes Console1984.protected_environments.map(&:to_sym), :production
  end
end
