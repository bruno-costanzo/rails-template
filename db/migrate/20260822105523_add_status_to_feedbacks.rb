class AddStatusToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :status, :string, default: "open", null: false
    add_column :feedbacks, :resolved_at, :datetime
  end
end
