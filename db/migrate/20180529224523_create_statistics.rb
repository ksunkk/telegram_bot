class CreateStatistics < ActiveRecord::Migration[5.2]
  def change
    create_table :statistics do |t|
      t.integer :valid_count, default: 0
      t.integer :invalid_count, default: 0
      t.belongs_to :telegram_user
      t.timestamps null: false
    end

    add_column :telegram_users, :statistic_id, :integer
  end
end
