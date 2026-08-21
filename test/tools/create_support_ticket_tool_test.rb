require "test_helper"

class CreateSupportTicketToolTest < ActiveSupport::TestCase
  test "is registered with the LLM under a human-friendly name" do
    tool = CreateSupportTicketTool.new(users(:one))
    assert_equal "create_support_ticket", tool.name
  end

  test "creates a feedback for the user it was built for, from the title and summary" do
    tool = CreateSupportTicketTool.new(users(:one))

    assert_difference("users(:one).feedbacks.count", 1) do
      tool.execute(title: "Chat page is slow", summary: "Pages take a long time to load for this person.")
    end

    feedback = users(:one).feedbacks.last
    assert_includes feedback.message, "Chat page is slow"
    assert_includes feedback.message, "Pages take a long time to load for this person."
  end

  test "returns a human-friendly confirmation with no technical details" do
    tool = CreateSupportTicketTool.new(users(:one))
    result = tool.execute(title: "Chat page is slow", summary: "Pages take a long time to load.")

    assert_equal "Got it - I've passed this along to the team. Thank you!", result
  end
end
