class CreateTelegramPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :telegram_permissions do |t|
      t.string  :action_name
      t.string  :name
      t.boolean :is_deleted, default: :false
    end
  end
end
