class RenameCurrentLevelInCharacterSkills < ActiveRecord::Migration[8.1]
  def change
    rename_column :character_skills, :current_level, :current_skill_level
    rename_column :character_skills, :target_level, :target_skill_level
  end
end
