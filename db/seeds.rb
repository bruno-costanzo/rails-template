# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

RubyLLM.models.load_from_json!
Model.save_to_database
RubyLLM.models.load_from_database!

if Rails.env.development?
  User.find_or_create_by!(email_address: "dev@example.com") do |user|
    user.name = "Dev User"
    user.password = "password"
    user.confirmed_at = Time.current
  end
end
