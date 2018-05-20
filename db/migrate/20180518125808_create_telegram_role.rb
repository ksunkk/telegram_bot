class CreateTelegramRole < ActiveRecord::Migration[5.2]
  def change
    create_table :telegram_roles do |t|
      t.string :code,       null: false
      t.string :name,       null: false
      t.string :is_deleted, default: false
    end
  end
end
