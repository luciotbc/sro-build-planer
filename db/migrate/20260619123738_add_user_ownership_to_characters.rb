class AddUserOwnershipToCharacters < ActiveRecord::Migration[8.1]
  def change
    # user_id: null:false requires a clean DB (run db:reset in dev after this migration)
    add_column :characters, :user_id, :integer, null: false
    add_index :characters, :user_id, name: "index_characters_on_user_id"
    add_foreign_key :characters, :users

    # server_level_cap: valid values 90/100/110/120/130; default 110 for backfill safety
    add_column :characters,
               :server_level_cap,
               :integer,
               null: false,
               default: 110
  end
end
