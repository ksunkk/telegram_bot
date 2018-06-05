class AddUniqueStatCount < ActiveRecord::Migration[5.2]
  def change
  	add_column :statistics, :dubles_count, :integer, default: 0
  end
end
