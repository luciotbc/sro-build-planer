class CreateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :skills do |t|
      t.integer :external_id, null: false, index: { unique: true } # skill_id
      t.string :external_skill_code, null: false, index: { unique: true } # skill_code
      t.references :skill_group, null: false
      t.integer :skill_level, null: false
      t.integer :sp_cost
      t.integer :mastery_level_req

      t.timestamps
    end
  end
end
