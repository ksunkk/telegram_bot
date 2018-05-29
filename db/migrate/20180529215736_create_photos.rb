class CreatePhotos < ActiveRecord::Migration[5.2]
  def change
    create_table :photos do |t|
      t.oid :photo, null: false
      t.belongs_to :organization
      t.timestamps null: false
    end
  end
end
