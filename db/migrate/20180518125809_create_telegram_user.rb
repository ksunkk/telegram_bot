class CreateTelegramUser < ActiveRecord::Migration[5.2]
  def change
    create_table :telegram_users do |t|
      t.integer :telegram_role_id
      t.string  :phone
      t.string  :name
      t.boolean :is_deleted, default: false
      t.boolean :is_verificated, default: true
      t.timestamps null: false
    end
  end
end
