class Feedback < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  validates :message, presence: true

  after_create_commit :create_github_issue_later

  private

  def create_github_issue_later
    CreateFeedbackIssueJob.perform_later(self)
  end
end
