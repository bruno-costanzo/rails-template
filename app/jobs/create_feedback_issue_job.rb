class CreateFeedbackIssueJob < ApplicationJob
  queue_as :default

  def perform(feedback)
    return unless GithubIssues.configured?

    GithubIssues.create(title: title_for(feedback), body: body_for(feedback), labels: [ "feedback" ])
  end

  private

  def title_for(feedback)
    "Feedback from #{feedback.user.email_address}"
  end

  def body_for(feedback)
    lines = [
      "From: #{feedback.user.email_address}",
      "App: #{Rails.application.class.module_parent_name} (#{Rails.env})"
    ]

    if feedback.photos.attached?
      lines << "Photos:"
      feedback.photos.each { |photo| lines << photo_url(photo) }
    end

    lines << "---"
    lines << feedback.message

    lines.join("\n")
  end

  def photo_url(photo)
    Rails.application.routes.url_helpers.feedback_photo_url(
      signed_id: photo.blob.signed_id,
      **Rails.application.config.action_mailer.default_url_options
    )
  end
end
