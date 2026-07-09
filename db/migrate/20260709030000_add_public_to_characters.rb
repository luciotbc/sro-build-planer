class AddPublicToCharacters < ActiveRecord::Migration[8.1]
  def change
    # Visibility flag for the shared-build page (spec 05 R11a). Default false —
    # a build is private until the owner opts in to sharing.
    add_column :characters, :public, :boolean, default: false, null: false
  end
end
