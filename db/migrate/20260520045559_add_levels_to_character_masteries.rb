class AddLevelsToCharacterMasteries < ActiveRecord::Migration[8.1]
  def change
    add_column :character_masteries, :current_level, :integer
    add_column :character_masteries, :target_level, :integer
  end
end
