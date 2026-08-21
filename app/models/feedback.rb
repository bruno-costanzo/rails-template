class Feedback < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  validates :message, presence: true
  validates :photos, content_type: %w[image/png image/jpeg image/webp], size: { less_than: 5.megabytes }

  after_create_commit :create_github_issue_later

  private

  def create_github_issue_later
    CreateFeedbackIssueJob.perform_later(self)
  end
end
