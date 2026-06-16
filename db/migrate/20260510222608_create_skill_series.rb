class CreateSkillSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_series do |t|
      t.references :mastery, null: false, foreign_key: true
      t.integer :row_position
      t.string :title
      t.string :icon_path

      t.timestamps
    end
  end
end
