class AddShareTokenToCharacters < ActiveRecord::Migration[8.1]
  class MigrationCharacter < ActiveRecord::Base
    self.table_name = "characters"
  end

  def up
    add_column :characters, :share_token, :string

    # Backfill existing characters with a permanent UUID token.
    MigrationCharacter.reset_column_information
    MigrationCharacter
      .where(share_token: nil)
      .find_each do |character|
        character.update_columns(share_token: SecureRandom.uuid)
      end

    change_column_null :characters, :share_token, false
    add_index :characters, :share_token, unique: true
  end

  def down
    remove_column :characters, :share_token
  end
end
