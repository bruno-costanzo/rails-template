class HealthCheck
  def self.call
    new.call
  end

  def call
    checks = { database: safely { database_alive? } }
    checks[:jobs] = safely { jobs_alive? } if solid_queue?
    checks
  end

  private

  def safely
    yield
  rescue StandardError
    false
  end

  def database_alive?
    ActiveRecord::Base.with_connection { |connection| connection.select_value("SELECT 1") }
    true
  end

  def jobs_alive?
    SolidQueue::Process.where("kind LIKE ?", "Supervisor%").where(last_heartbeat_at: SolidQueue.process_alive_threshold.ago..).exists?
  end

  def solid_queue?
    ActiveJob::Base.queue_adapter.is_a?(ActiveJob::QueueAdapters::SolidQueueAdapter)
  end
end
