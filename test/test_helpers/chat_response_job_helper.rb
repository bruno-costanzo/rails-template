module ChatResponseJobHelper
  def chat_response_job_with_retries_spent(chat)
    job = ChatResponseJob.new(chat.id)
    job.exception_executions[[ RubyLLM::Error ].to_s] = ChatResponseJob::RETRY_ATTEMPTS - 1
    job
  end
end

class ActiveSupport::TestCase
  include ChatResponseJobHelper
end
