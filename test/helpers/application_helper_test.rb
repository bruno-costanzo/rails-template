require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include LucideRails::RailsHelper

  test "lucide_icon renders an inline svg with the given class" do
    svg = lucide_icon("house", class: "size-4")

    assert_match %r{\A<svg[^>]*class="size-4"}, svg
  end
end
