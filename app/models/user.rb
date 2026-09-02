class User < ApplicationRecord
  DAILY_MESSAGE_LIMIT = 100

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :documents, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :ahoy_visits, dependent: :destroy, class_name: "Ahoy::Visit"
  has_many :ahoy_events, dependent: :destroy, class_name: "Ahoy::Event"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :email_confirmation, expires_in: 1.day do
    email_address
  end

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 48, 48 ]
    attachable.variant :medium, resize_to_fill: [ 200, 200 ]
  end

  has_one_attached :data_export

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :avatar, content_type: %w[image/png image/jpeg image/webp], size: { less_than: 5.megabytes }

  def initials
    name.to_s.split.first(2).filter_map { |part| part[0] }.join.upcase
  end

  def messages_remaining_today
    [ DAILY_MESSAGE_LIMIT - messages.where(role: "user", created_at: Time.current.all_day).count, 0 ].max
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end
end
