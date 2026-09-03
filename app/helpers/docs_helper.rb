module DocsHelper
  DOC_TAGS = %w[h1 h2 h3 h4 h5 h6 p a ul ol li blockquote pre code em strong del hr br table thead tbody tr th td].freeze
  DOC_ATTRIBUTES = %w[href id lang].freeze

  def doc_body(doc)
    sanitize doc.html, tags: DOC_TAGS, attributes: DOC_ATTRIBUTES
  end

  def doc_section_title(section)
    section == :guide ? t("docs.sections.guide") : t("docs.sections.architecture")
  end

  def doc_icon(doc)
    doc.section == :guide ? "book-open" : "layers"
  end

  def docs_search_index(docs)
    docs.flat_map do |doc|
      page = doc_path(doc.slug)

      [ { title: doc.title, heading: nil, summary: doc.summary, body: doc.body_text, path: page } ] +
        doc.headings.map { |heading| { title: doc.title, heading: heading[:text], summary: "", body: "", path: "#{page}#{heading[:anchor]}" } }
    end
  end
end
