class AddFieldsToSkillGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :skill_groups, :external_id, :integer
    add_reference :skill_groups, :skill_series, null: true, foreign_key: true
    add_column :skill_groups, :col_position, :integer
    add_column :skill_groups, :max_level, :integer
  end
end
