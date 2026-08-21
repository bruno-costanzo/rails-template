require "test_helper"

class SupportContextTest < ActiveSupport::TestCase
  test "returns the content of config/support_context.md" do
    assert_equal File.read(Rails.root.join("config/support_context.md")), SupportContext.content
  end

  test "returns an empty string when the file is missing" do
    original_path = SupportContext.method(:path)
    SupportContext.define_singleton_method(:path) { Rails.root.join("tmp/nonexistent_support_context.md") }

    assert_equal "", SupportContext.content
  ensure
    SupportContext.define_singleton_method(:path, original_path)
  end

  test "instructions include the binding rule and the support context" do
    assert_includes SupportContext.instructions, SupportContext::BINDING_RULE
    assert_includes SupportContext.instructions, SupportContext.content
  end
end
