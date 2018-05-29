class AddTelegramIdToUser < ActiveRecord::Migration[5.2]
  def change
  	add_column :telegram_users, :telegram_id, :integer
  end
end
