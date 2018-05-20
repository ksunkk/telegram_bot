class CreateTelegramPermissionsTelegramRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :roles_permissions do |t|
    	t.belongs_to :telegram_role,       index: true
    	t.belongs_to :telegram_permission, index: true 
    end
  end
end
