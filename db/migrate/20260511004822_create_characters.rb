class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.string :name
      t.references :race, null: false, foreign_key: true
      t.integer :current_level
      t.integer :target_level

      t.timestamps
    end
  end
end
