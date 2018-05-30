class AddChatIdToUser < ActiveRecord::Migration[5.2]
  def change
  	add_column :telegram_users, :chat_id, :integer
  end
end
