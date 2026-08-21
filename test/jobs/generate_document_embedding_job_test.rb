require "test_helper"

class GenerateDocumentEmbeddingJobTest < ActiveJob::TestCase
  test "stores the embedding and does not re-enqueue itself" do
    doc = users(:one).documents.create!(title: "Kamal", content: "Deploy")
    clear_enqueued_jobs
    stub_openai_embedding(vector: Array.new(Document::EMBEDDING_DIMENSIONS, 0.5))
    perform_enqueued_jobs only: GenerateDocumentEmbeddingJob do
      GenerateDocumentEmbeddingJob.perform_now(doc)
    end
    assert_equal Document::EMBEDDING_DIMENSIONS, doc.reload.embedding.size
    assert_no_enqueued_jobs only: GenerateDocumentEmbeddingJob
  end

  test "writing an embedding identical to the stored one does not re-enqueue" do
    doc = users(:one).documents.create!(title: "Kamal", content: "Deploy")
    stored_vector = Array.new(Document::EMBEDDING_DIMENSIONS, 0.5)
    doc.update!(embedding: stored_vector)
    clear_enqueued_jobs

    stub_openai_embedding(vector: stored_vector)
    perform_enqueued_jobs only: GenerateDocumentEmbeddingJob do
      GenerateDocumentEmbeddingJob.perform_now(doc)
    end

    assert_no_enqueued_jobs only: GenerateDocumentEmbeddingJob
  end
end
