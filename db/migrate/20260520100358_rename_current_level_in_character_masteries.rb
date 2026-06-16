class RenameCurrentLevelInCharacterMasteries < ActiveRecord::Migration[8.1]
  def change
    rename_column :character_masteries, :current_level, :current_mastery_level
    rename_column :character_masteries, :target_level, :target_mastery_level
  end
end
