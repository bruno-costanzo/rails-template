class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :user

  has_many_attached :pending_photos
  validates :pending_photos, content_type: %w[image/png image/jpeg image/webp], size: { less_than: 5.megabytes }

  scope :support, -> { where(support: true) }
end
