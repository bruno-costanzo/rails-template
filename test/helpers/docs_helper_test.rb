require "test_helper"

class DocsHelperTest < ActionView::TestCase
  test "doc_body strips javascript: and data: schemes from a link and an autolink" do
    markdown = <<~MARKDOWN
      # Title

      [click me](javascript:alert(1))

      <javascript:alert(1)>

      [image link](data:text/html,evil)
    MARKDOWN

    Tempfile.create([ "docs_helper_test_doc", ".md" ]) do |file|
      file.write(markdown)
      file.flush

      html = doc_body(Doc.new(file.path))

      assert_no_match(/href="javascript:/, html)
      assert_no_match(/href="data:/, html)
      assert_includes html, "click me"
    end
  end
end
