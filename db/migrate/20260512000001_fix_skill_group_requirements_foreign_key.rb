class FixSkillGroupRequirementsForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :skill_group_requirements, column: :required_group_id
    add_foreign_key :skill_group_requirements, :skill_groups, column: :required_group_id
  end
end
