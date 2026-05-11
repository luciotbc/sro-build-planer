class CreateSkillGroupRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_group_requirements do |t|
      t.references :skill_group, null: false, foreign_key: true
      t.references :required_group, null: false, foreign_key: true
      t.integer :required_level

      t.timestamps
    end
  end
end
