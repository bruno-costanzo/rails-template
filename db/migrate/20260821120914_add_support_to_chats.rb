class AddSupportToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :support, :boolean, default: false, null: false
  end
end
