class RenameMaxLevelInSkillGroups < ActiveRecord::Migration[8.1]
  def change
    rename_column :skill_groups, :max_level, :max_skill_level
  end
end
