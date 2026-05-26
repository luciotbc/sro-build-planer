class AddUniqueIndexToCharacterMasteriesAndSkills < ActiveRecord::Migration[8.1]
  def change
    add_index :character_masteries, %i[character_id mastery_id], unique: true
    add_index :character_skills, %i[character_id skill_group_id], unique: true
  end
end
