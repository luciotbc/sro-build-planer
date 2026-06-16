class CreateCharacterMasteries < ActiveRecord::Migration[8.1]
  def change
    create_table :character_masteries do |t|
      t.references :character, null: false, foreign_key: true
      t.references :mastery, null: false, foreign_key: true

      t.timestamps
    end
  end
end
