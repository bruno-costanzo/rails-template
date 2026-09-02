module MessageQuotaHelper
  def seed_messages(chat, count, role: "user", created_at: Time.current)
    Message.insert_all(Array.new(count) do
      { chat_id: chat.id, role: role, content: "Seeded", created_at: created_at, updated_at: created_at }
    end)
  end
end
