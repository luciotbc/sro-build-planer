module SharedBuildsHelper
  # One line per chosen mastery: "<Mastery> <current> → <target>" (task 021).
  def og_build_description(character)
    character
      .character_masteries
      .includes(:mastery)
      .sort_by { |cm| cm.mastery.id }
      .map do |cm|
        "#{cm.mastery.name} #{cm.current_mastery_level.to_i} → #{cm.target_mastery_level.to_i}"
      end
      .join("\n")
  end
end
