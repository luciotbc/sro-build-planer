class RenameRequiredLevelInSkillGroupRequirements < ActiveRecord::Migration[8.1]
  def change
    rename_column :skill_group_requirements,
                  :required_level,
                  :required_skill_level
  end
end
