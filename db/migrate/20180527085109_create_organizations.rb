class CreateOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :organizations do |t|
    	t.string :name
      t.string :phone
      t.text :address
      t.text :source
      t.integer :added_by
      t.boolean :is_deleted, default: false
      t.boolean :is_verified, default: false
      t.timestamps null: false
    end
  end
end
