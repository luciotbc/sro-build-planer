class CreateMasteries < ActiveRecord::Migration[8.1]
  def change
    create_table :masteries do |t|
      t.integer :external_id, null: false, index: { unique: true } # mastery_id
      t.string :name, null: false
      t.string :mastery_type, null: false # Weapon, Force, Physical, Magical, Support
      t.references :race, null: false, foreign_key: true

      t.timestamps
    end
  end
end
