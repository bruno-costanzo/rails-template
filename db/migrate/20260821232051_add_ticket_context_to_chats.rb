class AddTicketContextToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :ticket_context, :json
  end
end
