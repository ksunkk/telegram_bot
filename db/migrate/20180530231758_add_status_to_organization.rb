class AddStatusToOrganization < ActiveRecord::Migration[5.2]
  def change
  	add_column :organizations, :check_status, :integer, default: 2
  end
end
