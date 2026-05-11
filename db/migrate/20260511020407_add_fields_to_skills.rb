class AddFieldsToSkills < ActiveRecord::Migration[8.1]
  def change
    add_column :skills, :stack, :integer
    add_column :skills, :mp_cost, :integer
  end
end
