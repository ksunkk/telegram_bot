class AddValidateCountsToStats < ActiveRecord::Migration[5.2]
  def change
  	add_column :statistics, :corrections_count, :integer
  	add_column :statistics, :validates_count, :integer
  end
end
