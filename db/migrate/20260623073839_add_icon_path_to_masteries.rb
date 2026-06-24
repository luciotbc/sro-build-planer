class AddIconPathToMasteries < ActiveRecord::Migration[8.1]
  # Game icon paths (relative to app/assets/images), keyed by Mastery#external_id.
  # Source of truth is the `pict` attr on each <tab> in docs/import/skill_*.xml;
  # this map backfills rows imported before the column existed. New imports get
  # the value straight from the XML (SRO::XmlSkillsImporter).
  ICONS = {
    257 => "skillmastery/china/mastery_sword.png",
    258 => "skillmastery/china/mastery_spear.png",
    259 => "skillmastery/china/mastery_bow.png",
    273 => "skillmastery/china/mastery_gigong.png",
    274 => "skillmastery/china/mastery_gigong.png",
    275 => "skillmastery/china/mastery_gigong.png",
    276 => "skillmastery/china/mastery_water.png",
    513 => "skillmastery/europe/eu_warrior.png",
    514 => "skillmastery/europe/eu_wizard.png",
    515 => "skillmastery/europe/eu_rog.png",
    516 => "skillmastery/europe/eu_warlock.png",
    517 => "skillmastery/europe/eu_bard.png",
    518 => "skillmastery/europe/eu_cleric.png"
  }.freeze

  def up
    add_column :masteries, :icon_path, :string

    ICONS.each { |external_id, icon_path| execute(<<~SQL.squish) }
        UPDATE masteries SET icon_path = #{quote(icon_path)}
        WHERE external_id = #{quote(external_id)}
      SQL
  end

  def down
    remove_column :masteries, :icon_path
  end
end
