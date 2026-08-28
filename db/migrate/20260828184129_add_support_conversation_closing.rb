class AddSupportConversationClosing < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :closed_at, :datetime
    add_reference :feedbacks, :chat, foreign_key: true
  end
end
