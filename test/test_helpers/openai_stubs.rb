module OpenaiStubs
  def stub_openai_chat(content:)
    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "chatcmpl-test", object: "chat.completion", created: 0, model: "gpt-4o-mini",
        choices: [ { index: 0, message: { role: "assistant", content: content }, finish_reason: "stop" } ],
        usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 }
      }.to_json
    )
  end

  def stub_openai_chat_stream(chunks:)
    body = chunks.map { |content| server_sent_event(content: content) }.join
    body << server_sent_event(content: nil, finish_reason: "stop")
    body << "data: [DONE]\n\n"

    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
      status: 200,
      headers: { "Content-Type" => "text/event-stream" },
      body: body
    )
  end

  def stub_openai_embedding(vector:)
    stub_request(:post, "https://api.openai.com/v1/embeddings").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        object: "list", model: "text-embedding-3-small",
        data: [ { object: "embedding", index: 0, embedding: vector } ],
        usage: { prompt_tokens: 1, total_tokens: 1 }
      }.to_json
    )
  end

  private

  def server_sent_event(content:, finish_reason: nil)
    delta = content.nil? ? {} : { content: content }
    chunk = {
      id: "chatcmpl-test", object: "chat.completion.chunk", created: 0, model: "gpt-4o-mini",
      choices: [ { index: 0, delta: delta, finish_reason: finish_reason } ]
    }
    "data: #{chunk.to_json}\n\n"
  end
end

class ActiveSupport::TestCase
  include OpenaiStubs
end
