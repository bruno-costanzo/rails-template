RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.default_model = "gpt-4o-mini"
  config.default_embedding_model = "text-embedding-3-small"

  config.use_new_acts_as = true
end
