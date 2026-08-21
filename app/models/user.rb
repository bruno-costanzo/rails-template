class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 48, 48 ]
    attachable.variant :medium, resize_to_fill: [ 200, 200 ]
  end

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :avatar, content_type: %w[image/png image/jpeg image/webp], size: { less_than: 5.megabytes }

  def initials
    name.to_s.split.first(2).filter_map { |part| part[0] }.join.upcase
  end
end
