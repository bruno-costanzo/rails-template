class Doc
  GUIDES = %w[README.md CLAUDE.md].freeze
  ARCHITECTURE = "docs/architecture".freeze
  SUMMARY_LENGTH = 220
  NOT_A_PARAGRAPH = /\A(?:[#>|`\-*+]|\d+\.)/

  class Renderer < Redcarpet::Render::HTML
    def link(url, _title, content)
      %(<a href="#{escape(Doc.route(url) || url)}">#{content}</a>)
    end

    def codespan(code)
      route = Doc.route(code)
      span = "<code>#{escape(code)}</code>"

      route ? %(<a href="#{escape(route)}">#{span}</a>) : span
    end

    private
      def escape(text)
        ERB::Util.html_escape(text)
      end
  end

  MARKDOWN = Redcarpet::Markdown.new(
    Renderer.new(filter_html: true, safe_links_only: true, with_toc_data: true),
    fenced_code_blocks: true, tables: true, autolink: true, no_intra_emphasis: true, strikethrough: true
  )

  TABLE_OF_CONTENTS = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new(nesting_level: 2..2))

  attr_reader :path

  def initialize(path)
    @path = path
  end

  class << self
    def all
      (GUIDES + architecture_pages).map { |page| new(page) }
    end

    def find(slug)
      all.find { |doc| doc.slug == slug } || raise(ActiveRecord::RecordNotFound)
    end

    def route(reference)
      page, anchor = reference.to_s.split("#", 2)
      path = paths.find { |candidate| candidate == page || candidate == "#{ARCHITECTURE}/#{page}" }

      path && [ url_helpers.doc_path(slug_of(path)), anchor ].compact.join("#")
    end

    def summary_of(content)
      content.split(/\n{2,}/).map(&:strip).grep_v(NOT_A_PARAGRAPH).first.to_s.squish.truncate(SUMMARY_LENGTH)
    end

    def slug_of(path)
      path.delete_prefix("docs/").delete_suffix(".md")
    end

    private
      def paths
        GUIDES + architecture_pages
      end

      def architecture_pages
        Dir.glob(Rails.root.join(ARCHITECTURE, "*.md")).sort.map { |page| "#{ARCHITECTURE}/#{File.basename(page)}" }
      end

      def url_helpers
        Rails.application.routes.url_helpers
      end
  end

  def slug
    self.class.slug_of(path)
  end

  def section
    GUIDES.include?(path) ? :guide : :architecture
  end

  def title
    content[/^#\s+(.+)$/, 1].to_s.strip.presence || slug
  end

  def summary
    self.class.summary_of(content)
  end

  def html
    @html ||= MARKDOWN.render(content)
  end

  def headings
    @headings ||= Nokogiri::HTML5.fragment(TABLE_OF_CONTENTS.render(content)).css("a").map do |link|
      { text: link.text.strip, anchor: link["href"] }
    end
  end

  private
    def content
      @content ||= Rails.root.join(path).read
    end
end
