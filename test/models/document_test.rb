require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  def unit_vector(index)
    Array.new(Document::EMBEDDING_DIMENSIONS, 0.0).tap { |v| v[index] = 1.0 }
  end

  def create_document(title, index)
    doc = users(:one).documents.create!(title: title, content: "Body of #{title}")
    doc.update!(embedding: unit_vector(index))
    doc
  end

  test "embedding_source_text combines title and plain text content" do
    doc = users(:one).documents.create!(title: "Kamal", content: "<p>Deploy <strong>fast</strong></p>")
    assert_equal "Kamal\nDeploy fast", doc.embedding_source_text
  end

  test "semantic_search returns nearest documents first" do
    kamal = create_document("Kamal", 0)
    cooking = create_document("Cooking", 1)
    stub_openai_embedding(vector: unit_vector(0))
    results = Document.semantic_search("how to deploy")
    assert_equal kamal, results.first
    assert_includes results, cooking
  end

  test "saving enqueues an embedding refresh" do
    assert_enqueued_with(job: GenerateDocumentEmbeddingJob) do
      users(:one).documents.create!(title: "New", content: "text")
    end
  end
end
