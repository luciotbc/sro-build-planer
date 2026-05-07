class CreateRaces < ActiveRecord::Migration[8.1]
  def change
    create_table :races do |t|
      t.integer :external_id, null: false, index: { unique: true } # race_id
      t.string :name, null: false

      t.timestamps
    end
  end
end
