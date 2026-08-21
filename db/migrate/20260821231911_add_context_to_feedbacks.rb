class AddContextToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :context, :json
  end
end
