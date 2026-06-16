class CreateSkillGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_groups do |t|
      t.references :mastery, null: false, foreign_key: true
      t.string :external_group_code, null: false, index: { unique: true }
      t.string :name
      t.string :tooltip
      t.string :description
      t.string :icon_path

      t.timestamps
    end
  end
end
