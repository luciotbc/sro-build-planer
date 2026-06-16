class CreateCharacterSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :character_skills do |t|
      t.references :character, null: false, foreign_key: true
      t.references :skill_group, null: false, foreign_key: true
      t.integer :current_level
      t.integer :target_level

      t.timestamps
    end
  end
end
