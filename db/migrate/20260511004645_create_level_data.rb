class CreateLevelData < ActiveRecord::Migration[8.1]
  def change
    create_table :level_data do |t|
      t.integer :level
      t.integer :xp_required
      t.integer :sp_gained
      t.integer :sp_cumulative

      t.timestamps
    end
  end
end
